---
name: vcu-codebase-documentation
description: Guidelines for writing natural, human-style technical module notes, onboarding docs, and architecture overviews in VCU_firmware and embedded C/Zephyr projects (using rtc_sync.md as the baseline). Use whenever asked to write, rewrite, review, or summarize documentation in documentation/notes/, documentation/testing/, or similar developer handover docs so they read like concise teammate notes (~50–90 lines) rather than AI-generated line-by-line code translations.
---

# Technical Module & Codebase Documentation (`rtc_sync.md` Baseline)

Documentation in `documentation/notes/` and `documentation/testing/` serves as **onboarding and handover notes** for teammates or thesis readers—not as an API reference or a line-by-line English translation of the C source code.

## 1. Target Audience & Goal

- **Reader:** A teammate or future maintainer who knows embedded C and Zephyr basics, but has **never looked at this specific subsystem**.
- **Goal:** Give them the mental model of *why* the module exists, *how* the hardware and software signals fit together, and *how* to test or configure it on the bench in under two minutes of reading (~50–90 lines).

## 2. Structural Template (The 5 Building Blocks)

### A. Context & "Why" First (Opening Paragraph)
Start with what the system needs before naming internal functions or state machines:
- **What problem does it solve?** State the system-level purpose in the first two sentences (e.g., in `rtc_sync.md`: the VCU needs wall-clock time for logging and to act as the time-sync master on the Cyphal CAN bus).
- **Where does it live?** Mention the 1–2 main source files inline (e.g., `rtc.c`, driven by the INS thread in `ins.c`) instead of creating a separate `Files` table.
- **What is the physical or architectural constraint?** Explain *why* a naive solution fails (e.g., UART messages from the SBG Ellipse arrive with variable millisecond delay, so we combine the GPIO `PPS` pulse on the exact second boundary with the subsequent UART `UTC` frame).
- **Hardware / Devicetree status & boot fallbacks:** Call out if hardware is currently emulated or mocked (e.g., `zephyr,rtc-emul` via the `rtc` devicetree alias vs. an external battery-backed RTC later) and any boot fallback behavior (such as `rtc_init_default_time()`).

### B. Core Mechanism & Timing (1 Section + At Most 1 Visual)
Explain the non-obvious trick of the implementation in plain prose:
- **Focus on the physical timeline, not the C syntax:** Explain the core compensation or algorithm intuitively (e.g., time elapses between the `PPS` interrupt at `edge_ticks` and the `rtc_set_time()` call on the INS thread at `now_ticks`, so adding `now_ticks - edge_ticks` compensates for UART and polling latency).
- **One diagram that shows what code cannot:** Keep a diagram only when it visualizes **timing, signal flow, or hardware wiring** (such as the single PlantUML timing diagram in `rtc_sync.md`). Never draw `if/else` control flow, C function call graphs, or small state enums as PlantUML diagrams—the C code already shows that better.
- **One sentence on concurrency:** Instead of documenting spinlocks, helper functions, and `errno` codes (`-EAGAIN`, `-ENOTSUP`, `-ENOSYS`), summarize the threading contract in one line (e.g., *"All GNSS callbacks/ISRs only copy timestamps under a spinlock; the actual RTC bus calls happen on the INS thread so nothing blocks."*).

### C. Downstream / System Integration
If another subsystem depends on this module, give it a short, focused paragraph:
- Explain what entry point it consumes and the behavioral guarantee (e.g., how `rtc_sync_get_utc_usec()` feeds the Cyphal time-sync publisher after `CONFIG_RTC_SYNC_TIME_INIT_SAMPLES` valid edges and slews corrections at `CONFIG_RTC_SYNC_TIME_SLEW_PPM` so CAN bus slave nodes never see time jump backwards).

### D. Bench / Dev Workflow ("How do I run this at my desk?")
Every hardware-dependent module needs a short, copy-pasteable section for testing when the full vehicle or sensor harness isn't connected:
- State the exact bench scenario (e.g., SBG Ellipse connected via `RS232` only, without the `PPS` wire).
- Provide the exact `west build` one-liner or `app/prj.conf` option:
  ```bash
  west build -b mr_canhubk3 app -- -DCONFIG_RTC_SYNC_SIMULATED_PPS=y
  ```
- State the trade-off in one sentence (e.g., accurate only to a few milliseconds due to UART jitter and disables drift calibration, so use it for local bench testing only).

### E. Optional Features & Honest Limitations
End with 3–4 short bullet points covering optional modes and what is *not* implemented yet:
- **Optional modes:** Briefly describe optional features and their main knob (e.g., `CONFIG_RTC_SYNC_CALIBRATION` comparing the RTC 1-second rollover against `PPS` over `CONFIG_RTC_SYNC_CALIB_WINDOW_S` to adjust hardware calibration in ppb) without pasting formulas or activity diagrams.
- **Known limitations / future work:** Be explicit about current shortcuts (e.g., boot-only RTC write without periodic resync; uncompensated `I2C`/`SPI` bus write latency). This tells the next developer or thesis reader exactly where to pick up.

## 3. Style & Tone Descriptors (Human vs. AI-Generated)

| Descriptor | Good Project Style (Baseline: `rtc_sync.md`) | Anti-Pattern to Avoid |
|---|---|---|
| **Voice** | Direct, practical ("We get the current date and time...", "On a bench setup where...") | Detached textbook/spec prose ("The module transitions to `WAIT_UTC` upon invocation of...") |
| **Config & Symbols** | Mention only the 2–4 `CONFIG_*` flags or entry-point functions that a developer actually touches, woven naturally into sentences | Dumping full `Kconfig` tables, `Files` tables, or listing every internal static helper |
| **Formatting** | Short paragraphs + plain bullet points (`- the PPS pulse...`) | Starting every bullet with a bolded label (`- **PPS edge:**`, `- **UTC sample:**`) |
| **Math & Logic** | Explain the *reason* behind an equation in words ("add the elapsed kernel ticks (`now_ticks - edge_ticks`)") | Pasting pseudocode blocks (`for k in {0, 1}`) or standard C trivia (`struct tm` `tm_year` since 1900, `tm_mon` 0–11) |
| **Diagrams** | At most 1 diagram per note, used only for timing or hardware topology | Multiple PlantUML component, sequence, state, and activity diagrams that mirror C `if/else` branches |

## 4. Baseline Example (`documentation/notes/rtc_sync.md`)

Use this structure and tone as the reference standard:

```markdown
# RTC Sync (GNSS UTC + PPS)

The VCU needs wall-clock time for logging and to act as the time-sync master on the Cyphal CAN bus.
We get the current date and time from the SBG Ellipse-D INS (`rtc.c`, driven by the INS thread in `ins.c`).

Because the UTC message arrives over UART with variable delay, we combine two signals from the INS:
- the PPS pulse on a GPIO pin, which triggers an ISR on the exact second boundary and records `k_uptime_ticks()`
- the UTC message over UART, which arrives a few milliseconds later and tells us which second that pulse belonged to

The RTC is accessed through Zephyr's generic `rtc` API (`rtc` devicetree alias). Right now the board uses `zephyr,rtc-emul` as a stand-in, so switching to an external battery-backed RTC later only requires a devicetree change. At boot, `rtc_init_default_time()` sets a fallback timestamp (`2025-01-01 00:00:00`) so early SD-card logs still have valid timestamps before GNSS gets a fix.

## How the sync works

When a valid UTC message arrives shortly after a PPS edge (within `CONFIG_RTC_SYNC_MAX_UTC_LATENCY_MS`, default 500 ms), the INS thread pairs them up and sets the RTC once per boot.

Since some time has already passed between the PPS pulse and the actual `rtc_set_time()` call in the INS thread, we don't just write the raw UTC timestamp. Instead, we add the elapsed kernel ticks (`now_ticks - edge_ticks`) to the UTC second from the edge so UART and polling delays are compensated:

[Single timing diagram only]

All GNSS callbacks/ISRs only copy timestamps under a spinlock; the actual RTC bus calls happen on the INS thread so nothing blocks.

## Cyphal time-sync master

`rtc_sync` also feeds the Cyphal network time-sync publisher (`rtc_sync_get_utc_usec()`). After collecting a few valid GNSS edges (`CONFIG_RTC_SYNC_TIME_INIT_SAMPLES`, default 3), it tracks the microsecond offset between `k_uptime_ticks()` and UTC. Subsequent drift corrections are slewed (`CONFIG_RTC_SYNC_TIME_SLEW_PPM`, default 1000 ppm) instead of stepped, so slave nodes on the bus never see time jump backwards.

## Testing without the PPS wire (Simulated PPS)

On a bench setup where the SBG Ellipse is only connected via RS232 without the PPS wire, you can estimate the PPS edge from the incoming UTC frame's millisecond field:

west build -b mr_canhubk3 app -- -DCONFIG_RTC_SYNC_SIMULATED_PPS=y
(or set `CONFIG_RTC_SYNC_SIMULATED_PPS=y` in `app/prj.conf`).

This is only accurate to a few milliseconds (UART jitter) and disables drift calibration, so only use it for local testing.

## Drift calibration & current limitations

- If `CONFIG_RTC_SYNC_CALIBRATION` is enabled, the module compares the RTC's 1-second rollover against the PPS pulse over a window (`CONFIG_RTC_SYNC_CALIB_WINDOW_S`, default 300 s) and adjusts the RTC hardware calibration in ppb.
- The system RTC is only written once after boot (no periodic resync yet if the RTC drifts and hardware calibration isn't used).
- I2C/SPI bus transfer time when writing to an external RTC chip is not compensated yet.
```

## 5. Checklist Before Finishing a Doc

- [ ] Can a new team member tell in the first 5 lines *why* this module exists and which hardware/threads it talks to?
- [ ] Are redundant `Files` tables, full `Kconfig` tables, and `if/else` PlantUML diagrams removed?
- [ ] Are bullet points written naturally without robotic `- **Label:**` prefixes on every line?
- [ ] Is there a copy-pasteable bench/simulation command (`mr_canhubk3` or `native_sim`) for testing without the full vehicle setup?
- [ ] Are current shortcuts and known limitations stated honestly at the end?
