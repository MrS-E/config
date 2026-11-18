---
name: technical-documentation
description: "Create standalone, reproducible Obsidian-flavored technical documentation notes for troubleshooting, incidents, configurations, deployments, or development workflows. Synthesizes information from the active Junie session, past Junie sessions (~/.junie/sessions), pasted chat transcripts/logs, and local system/repository verification. TRIGGER when: the user asks to document a fix, problem, setup, configuration, or deployment; create an Obsidian note, technical note, runbook, or knowledge-base article; or turn a chat/session into documentation."
---

# Technical Documentation (Obsidian Knowledge-Base Skill)

Turn technical investigations, troubleshooting sessions, configurations, deployments, or development workflows into **standalone, reproducible Obsidian Markdown documentation**.

The source conversation, session history, or raw logs are **working material only**—the resulting document must read as if it were written from scratch as a clean engineering reference or runbook.

---

## 1. Language & Tone

- **Match the user's request language:**
  - If the user asks in **German**, write the note in German (use German section headings and callout titles). If the `simeon-stix-schreibstil` skill is also active or requested, follow Swiss orthography (`ss` instead of `ß`).
  - If the user asks in **English**, write the note in English (use English section headings and callout titles).
- **Zero chat artifacts:**
  - Never include dialogue, chat chronology, or conversational filler.
  - Never write phrases like *"the user said"*, *"in the chat"*, *"we tried earlier"*, or *"as discussed in the session"*.
  - Never add a *"Source conversation"* or *"Original chat"* section unless explicitly requested.
- **Epistemic precision:**
  - Clearly separate verified facts from hypotheses using explicit labels:
    - German: `Bestätigte Ursache`, `Wahrscheinliche Ursache`, `Mögliche Ursache`, `Nicht verifiziert`, `Unbekannt`
    - English: `Confirmed root cause`, `Likely cause`, `Possible cause`, `Unverified`, `Unknown`
  - Never present unverified guesses as confirmed facts.
  - Never invent version numbers, flags, command outputs, or test results.

---

## 2. Context Gathering & Local Verification

Gather technical facts from whichever source(s) apply, then verify missing details locally before giving up:

1. **Current Junie session:** Extract the problem statement, environment, commands run, error outputs, root cause, and final working fix from the active session.
2. **Past Junie sessions:** If the user refers to a previous session or earlier task, read `~/.junie/sessions/index.jsonl` and the relevant `~/.junie/sessions/<sessionId>/transcript.md` (plus subagent transcripts if applicable).
3. **Pasted chats, logs, or notes:** Distill the technical signal from pasted conversations or terminal dumps, stripping repetitive back-and-forth, typos, and dead-end chatter.
4. **Local verification (Do this before marking anything `Unknown`):**
   - When the current machine or repository is the relevant environment and a detail is missing from the chat (e.g., exact OS/kernel version, tool/package version, file path, systemd unit content, or active config file), inspect the local filesystem or run safe, read-only commands to retrieve the exact value.
   - Only fall back to `Unbekannt` / `Unknown` or `Nicht verifiziert` / `Unverified` if the environment is remote/external or the state is no longer inspectable.

---

## 3. Obsidian Formatting & Rich Syntax

### YAML Frontmatter

Start every note with Obsidian-compatible YAML frontmatter:

```yaml
---
title: "<Short, precise, searchable title>"
date: YYYY-MM-DD
type: technical-documentation
category: "<troubleshooting | incident | configuration | deployment | development>"
status: "<resolved | partially-resolved | unresolved | active>"
tags:
  - technical-documentation
  - "<category>"
  - "<component/platform/tool tags, e.g. ssh, systemd, fedora, docker>"
aliases:
  - "<optional short alias or primary error code>"
related:
  - "[[<optional related Obsidian note>]]"
---
```

*(Omit `aliases` or `related` when none apply.)*

### Obsidian Callouts

Use native Obsidian callouts purposefully to improve scannability:

- **Executive Summary at the top (`> [!abstract]`):**
  Place immediately below `# <Title>` so a reader gets the entire takeaway in 10 seconds.
- **Warnings & Destructive Actions (`> [!warning]` / `> [!danger]`):**
  Place before commands that require `sudo`, overwrite configs, restart critical services, or risk data loss.
- **Environment & Platform Nuances (`> [!info]` / `> [!tip]`):**
  Highlight differences between OS variants (e.g., Fedora vs. Fedora Atomic, macOS vs. Linux), GUI vs. CLI behavior, or socket/agent quirks.
- **Collapsible Details (`> [!example]-` / `> [!failure]-`):**
  Use foldable callouts (note the trailing `-`) for lengthy log outputs, full stack traces, or secondary failed approaches so they remain preserved without cluttering the main solution path.
- **Open Questions (`> [!question]`):**
  Highlight remaining unknowns or follow-up checks.

### Code, Logs, Links & Diagrams

- **Fenced code blocks:** Always specify the language (`bash`, `sh`, `zsh`, `yaml`, `ini`, `toml`, `json`, `sshconfig`, `systemd`, `python`, `diff`, `text`, `mermaid`).
- **Exact error preservation:** Keep key error messages and log lines verbatim inside `text` code blocks so they can be found via full-text search.
- **Inline code:** Wrap all filenames, paths, CLI flags, environment variables, package names, service units, and error codes in single backticks (`` ` ``).
- **Wikilinks:** Use `[[Note Name]]` or `[[Note Name|Display Text]]` when referencing related systems, runbooks, or concepts in the vault.
- **Diagrams:** Include at most one `mermaid` diagram (`sequenceDiagram`, `flowchart`, or `stateDiagram-v2`) **only** when visualizing multi-component interaction, signal timing, or network/auth flow adds clarity beyond prose and config blocks.

---

## 4. Adaptive Section Blueprints by Category

Select the blueprint matching the note's `category`. **Only include sections that contain real technical signal—never emit empty placeholder sections.**

### Blueprint A: `troubleshooting` / `incident`
Use when documenting a bug, failure, error, crash, or root-cause investigation.

1. **`# <Title>` + `> [!abstract] Zusammenfassung` / `Summary`**
   - 3–4 bullets: Problem, Root Cause, Solution, Resolution Status. Must be self-contained.
2. **`## Umgebung` / `## Environment`**
   - Compact Markdown table (`Komponente | Wert` / `Component | Value`) with confirmed OS, application, version, hardware, runtime, or deployment target.
3. **`## Symptome` / `## Symptoms`**
   - Verbatim error message or log snippet in a `text` block.
   - When it occurred, affected component/feature, trigger conditions, and reproducibility.
4. **`## Ursache` / `## Root Cause`**
   - State confidence level explicitly (**Bestätigte Ursache** / **Wahrscheinliche Ursache** / **Mögliche Ursachen** / **Ursache nicht abschließend geklärt**).
   - Explain the technical mechanism connecting the cause to the observed symptoms.
5. **`## Diagnose und Untersuchung` / `## Diagnosis & Investigation`** *(omit if trivial)*
   - Document only steps that yielded technical insight (1. What was checked, 2. Why, 3. Result, 4. Conclusion). Omit dead-end chat noise.
6. **`## Lösung` / `## Solution`**
   - Numbered, reproducible step-by-step instructions for the working fix.
   - For each key command, state: what it does, which `<PLACEHOLDERS>` must be replaced, whether elevated privileges (`sudo`) are required, and the expected output.
   - Precede destructive steps with a `> [!warning]` or `> [!danger]` callout and backup instructions.
7. **`## Konfiguration` / `## Configuration`** *(include when config files are involved)*
   - Show the working configuration in properly typed code blocks.
   - Distinguish between **mandatory settings**, **optional tuning**, **environment-specific paths/values**, and **example placeholders**.
8. **`## Überprüfung` / `## Verification`**
   - Exact verification commands, functional tests, relevant log checks, and expected output proving the issue is resolved.
9. **`## Nicht funktionierende Ansätze` / `## Failed Approaches`** *(include only if non-obvious)*
   - Document plausible approaches that failed so future readers do not repeat them: what was tried, result, why it failed, and when it might still apply. Can use collapsible `> [!failure]-` callouts.
10. **`## Betriebshinweise & Sicherheit` / `## Operational Notes & Security`** *(include when applicable)*
    - Required restarts/reloads, service/socket ordering, permissions, CLI vs. GUI differences, dev vs. prod caveats, and security implications.
11. **`## Kurzreferenz` / `## Quick Reference`**
    - Copy-paste TL;DR at the bottom (1–3 essential commands or steps) for engineers who already know the context.
12. **`## Offene Fragen` / `## Open Questions`** *(omit if everything is resolved and verified)*
    - List only genuine unresolved items or unverified assumptions inside a `> [!question]` callout or bullet list.

---

### Blueprint B: `configuration` / `deployment`
Use when documenting how a tool, service, system setting, SSH/network setup, or deployment pipeline is configured and operated (where no bug/incident is the primary focus).

1. **`# <Title>` + `> [!abstract] Zusammenfassung` / `Summary`**
   - Goal of the setup, target system/scope, and key mechanism used.
2. **`## Umgebung & Voraussetzungen` / `## Environment & Prerequisites`**
   - Environment table + required packages, permissions, hardware tokens, or dependencies.
3. **`## Architektur & Funktionsweise` / `## Architecture & How It Works`** *(optional)*
   - Brief explanation of how components interact (with a `mermaid` diagram if helpful).
4. **`## Einrichtung` / `## Step-by-Step Setup`**
   - Numbered, reproducible installation/deployment steps with command explanations, `<PLACEHOLDERS>`, and privilege requirements.
5. **`## Konfiguration` / `## Configuration Reference`**
   - Annotated working configuration files (`yaml`, `ini`, `toml`, `sshconfig`, `json`, etc.), separating mandatory, optional, and environment-specific settings.
6. **`## Überprüfung` / `## Verification`**
   - Commands and expected outputs to confirm the setup works end-to-end.
7. **`## Betriebshinweise, Sicherheit & Stolpersteine` / `## Operations, Security & Pitfalls`**
   - Service restarts, secret management, backup paths, platform differences, and any gotchas discovered during setup.
8. **`## Kurzreferenz` / `## Quick Reference`**
   - Essential day-2 operations (status check, reload, log inspection).

---

### Blueprint C: `development`
Use when documenting a codebase mechanism, developer workflow, build/test procedure, or technical design decision.

1. **`# <Title>` + `> [!abstract] Zusammenfassung` / `Summary`**
   - Purpose, problem solved, and primary files/modules involved.
2. **`## Kontext & Rahmenbedingungen` / `## Context & Constraints`**
   - Why this implementation or workflow exists and why naive alternatives fail.
3. **`## Funktionsweise` / `## Core Mechanism`**
   - Concise technical explanation of data/control flow, key entry points, and invariants (optionally with 1 `mermaid` diagram).
4. **`## Verwendung & Konfiguration` / `## Usage & Configuration`**
   - Build/run commands, important config flags, and developer workflow examples.
5. **`## Überprüfung & Tests` / `## Verification & Testing`**
   - How to run tests, reproduce scenarios, or validate behavior locally.
6. **`## Einschränkungen & Offene Punkte` / `## Limitations & Open Items`** *(if applicable)*
   - Known shortcuts, edge cases, or future work.

---

## 5. Security & Secret Scrubbing Rules (Mandatory)

- **Never output real secrets:** Strip all passwords, API keys, bearer tokens, PINs, private keys, cookies, or sensitive credentials found in chats, session transcripts, or local files.
- **Use explicit placeholders:** Replace sensitive values with `<PASSWORD>`, `<API_KEY>`, `<TOKEN>`, `<PRIVATE_KEY>`, `<USER>`, or `<HOST>`.
- **Flag privilege escalation & blast radius:** Explicitly mark commands requiring `sudo` / root privileges and warn before any operation that modifies system partitions, firewall rules, SSH access, or production state.
- **Mention backups:** Whenever an existing configuration file or database is modified in place, include a backup step or note beforehand.

---

## 6. Quality Checklist Before Output

Verify every generated note against this checklist before saving or returning it:

- [ ] **Standalone readability:** Can an engineer understand and reproduce the note without ever seeing the source chat or session?
- [ ] **No chat leakage:** Are all references to *"the chat"*, *"the user"*, and conversational chronology completely removed?
- [ ] **Adaptive structure:** Does the section layout match the `category`, with zero empty or boilerplate sections?
- [ ] **Local verification done:** Were missing environment versions, paths, or config snippets checked locally when possible instead of blindly marked `Unknown`?
- [ ] **Epistemic honesty:** Are unconfirmed causes clearly marked as `Likely` / `Unverified` rather than stated as fact?
- [ ] **Exact error messages:** Are key log lines and error strings preserved verbatim in `text` blocks?
- [ ] **Reproducible commands:** Are commands complete, placed in language-tagged code blocks, with `<PLACEHOLDERS>` and `sudo` requirements explained?
- [ ] **Secrets scrubbed:** Are all tokens, passwords, keys, and PINs replaced with `<PLACEHOLDERS>`?
- [ ] **Verification included:** Is there a concrete command or test with expected output to confirm success?
- [ ] **Obsidian formatting:** Does the note have valid YAML frontmatter, an `> [!abstract]` summary callout, and backticks around all technical identifiers?

---

## 7. Reference Guide

| Load when | File |
| :--- | :--- |
| Ready-to-use German & English Markdown templates for `troubleshooting`/`incident` and `configuration`/`deployment` notes | `references/templates-and-examples.md` |
