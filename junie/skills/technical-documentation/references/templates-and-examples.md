# Obsidian Technical Documentation Templates & Examples

Use these concrete Markdown templates as structural references when generating notes for each category.

---

## 1. `troubleshooting` / `incident` Template (German)

```markdown
---
title: "<Kurzer, präziser Titel des Problems / der Lösung>"
date: YYYY-MM-DD
type: technical-documentation
category: troubleshooting
status: resolved
tags:
  - technical-documentation
  - troubleshooting
  - "<komponente>"
aliases:
  - "<Fehlercode oder Kurzbezeichnung>"
related:
  - "[[<Verwandte Notiz>]]"
---

# <Kurzer, präziser Titel>

> [!abstract] Zusammenfassung
> - **Problem:** <Was hat nicht funktioniert und welche Auswirkung hatte es?>
> - **Ursache:** <Bestätigte oder wahrscheinliche technische Ursache in einem Satz.>
> - **Lösung:** <Kernmaßnahme, die das Problem behoben hat.>
> - **Status:** Vollständig gelöst / Teilweise gelöst (mit Workaround).

## Umgebung

| Komponente | Wert |
|---|---|
| Betriebssystem | `<OS + Version / Kernel>` |
| Anwendung / Dienst | `<Name + Version>` |
| Laufzeit / Hardware | `<Relevante Details>` |
| Konfigurationspfad | `<Pfad zur relevanten Datei>` |

## Symptome

Unter `<Auslöser / Bedingung>` schlägt `<Funktion / Dienst>` reproduzierbar fehl:

```text
<Exakte Fehlermeldung oder relevanter Log-Auszug>
```

- **Auftreten:** <z. B. nach System-Upgrade / nur unter Wayland / beim Start über systemd>
- **Reproduzierbarkeit:** <Immer reproduzierbar / sporadisch unter Bedingung X>

## Ursache

**Bestätigte Ursache:** *(oder: **Wahrscheinliche Ursache** / **Ursache nicht abschließend geklärt**)*

<Technische Erklärung, warum der Fehler auftritt und wie die Symptome daraus folgen.>

## Diagnose und Untersuchung

### 1. <Geprüfter Aspekt, z. B. Socket- und Dienststatus prüfen>

```bash
<diagnose-befehl>
```

- **Ergebnis:** `<Beobachtete Ausgabe oder Befund>`
- **Schlussfolgerung:** <Technische Bedeutung für die Eingrenzung>

## Lösung

> [!warning] Vorab-Sicherung
> Vor dem Überschreiben von `<Pfad>` ein Backup anlegen. Schritt 2 erfordert `sudo`-Rechte.

1. **Konfiguration sichern und anpassen**

   ```bash
   cp <pfad/zur/config> <pfad/zur/config>.bak
   ```

2. **Dienst / Einstellung korrigieren**

   ```bash
   sudo <befehl> --option <PLACEHOLDER>
   ```

   - `<PLACEHOLDER>`: <Erklärung, womit der Platzhalter zu ersetzen ist>
   - **Erwartetes Ergebnis:** <Was der Befehl bewirkt / ausgibt>

## Konfiguration

Relevanter Auszug aus `<pfad/zur/datei>`:

```ini
# Zwingend erforderlich:
<key> = <value>

# Optional / umgebungsspezifisch:
<optional_key> = <EXAMPLE_VALUE>
```

## Überprüfung

```bash
<prüfbefehl>
```

**Erwartetes Ergebnis:**

```text
<Erwartete Ausgabe bei erfolgreicher Behebung>
```

> [!failure]- Nicht funktionierende Ansätze
> - **<Versuchter Ansatz 1>:** Führte zu `<Ergebnis>`, da `<technischer Grund>`. Nur sinnvoll, wenn `<Bedingung>`.

## Betriebshinweise & Sicherheit

> [!info] Hinweise für den laufenden Betrieb
> - Nach Änderungen an `<Datei>` muss `<Dienst>` via `systemctl restart <dienst>` neu gestartet werden.
> - <Unterschiede zwischen CLI/GUI oder Dev/Prod, falls relevant.>

## Kurzreferenz

```bash
# 1. Konfiguration prüfen
<befehl-1>

# 2. Dienst neu laden & Status verifizieren
<befehl-2>
```
```

---

## 2. `configuration` / `deployment` Template (English)

```markdown
---
title: "<Concise Setup or Deployment Title>"
date: YYYY-MM-DD
type: technical-documentation
category: configuration
status: active
tags:
  - technical-documentation
  - configuration
  - "<tool-or-platform>"
related:
  - "[[<Related System Note>]]"
---

# <Concise Setup or Deployment Title>

> [!abstract] Summary
> - **Goal:** <What capability or service this setup provides.>
> - **Scope:** <Target host/OS/environment and main components involved.>
> - **Mechanism:** <1-sentence summary of how the configuration works.>

## Environment & Prerequisites

| Component | Value |
|---|---|
| OS / Platform | `<OS + version>` |
| Package / Tool | `<Package + version>` |
| Config Location | `<Path>` |

**Prerequisites:**
- Package `<pkg>` installed (`<install command>`).
- Access to `<hardware token / network / permission>`.

## Step-by-Step Setup

1. **Install required packages**

   ```bash
   sudo <package-manager> install <package-name>
   ```

2. **Configure `<component>`**

   Create or update `<path/to/config>` (back up any existing file first).

## Configuration Reference

File: `<path/to/config>`

```yaml
# Mandatory settings
service:
  enabled: true
  endpoint: "<HOST>:443"
  auth_token: "<API_TOKEN>"

# Optional / environment-specific tuning
timeouts:
  read_ms: 5000
```

- **Mandatory:** `service.enabled`, `service.endpoint`, `service.auth_token` (replace `<API_TOKEN>` with token from secret store).
- **Environment-specific:** Adjust `timeouts.read_ms` on high-latency links.

## Verification

Run the following check to confirm `<service/tool>` is active and responding:

```bash
<verification-command>
```

**Expected Result:**

```text
<Expected clean output>
```

## Operations, Security & Pitfalls

> [!warning] Security & Maintenance Notes
> - Never commit `<path/to/config>` containing a live `<API_TOKEN>` without a Git clean filter or secret manager.
> - Restart `<service>` after changing `<key>`.

## Quick Reference

```bash
# Validate config syntax
<validate-cmd>

# Reload service and inspect logs
systemctl --user restart <service> && journalctl --user -u <service> -n 20
```
```
