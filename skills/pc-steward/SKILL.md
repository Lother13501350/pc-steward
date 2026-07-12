---
name: pc-steward
description: AI PC health steward for Windows. Scans the machine with bundled read-only PowerShell scanners, diagnoses performance bottlenecks with concrete evidence (memory pressure, startup bloat, disk health and space, junk files, system error logs), and applies only whitelisted, reversible, user-approved fixes with automatic registry backups. Use this whenever the user says their computer is slow, laggy, freezing, or loud, asks to scan / check / diagnose / optimize / clean up / speed up their PC, asks about startup programs, RAM or memory pressure, disk space, or overall system health — including phrasings like "my pc is slow", "why is my laptop lagging", "speed up boot", "電腦變慢", "掃描電腦", "優化電腦", "開機好慢" — even when no specific tool is named.
---

# PC Steward

Act as the user's computer steward: diagnose first with evidence, explain in plain
language, change nothing without approval, and make every change reversible.

All scripts live under this skill's directory. Run them with:

```
powershell -NoProfile -ExecutionPolicy Bypass -File <skill-dir>/scripts/<path>.ps1
```

Every script prints a single JSON object to stdout.

## Principles (why this skill is trusted)

1. **Scan is read-only.** The `scripts/scanners/` set never modifies anything.
   Run scanners freely; never improvise extra commands that mutate state.
2. **Diagnosis is evidence-based.** Every finding you report must cite numbers
   from scanner output ("Discord's 6 processes hold 744 MB"), never generic
   advice ("disabling telemetry makes Windows faster").
3. **Fixes are whitelisted.** Only the bundled `scripts/actions/` scripts may
   change system state. If a fix has no action script, describe it and let the
   user do it manually — do not write ad-hoc mutation commands.
4. **Everything is reversible.** Action scripts back up affected registry keys
   as .reg files before touching them and print the backup location. Always
   pass the backup path and undo instructions on to the user.

## Workflow

### Phase 1 — Scan (read-only)

Run all seven scanners. They are independent — run them in parallel:

| Scanner | What it measures |
|---|---|
| `scanners/system.ps1` | CPU model/load, RAM total/free, commit %, uptime, GPUs, power plan |
| `scanners/processes.ps1` | Top processes by RAM and instantaneous CPU; multi-process app groups |
| `scanners/startup.ps1` | Every autostart entry (Run keys + startup folders) with enabled/disabled state |
| `scanners/disks.ps1` | Physical disk health, volume free space, page file usage |
| `scanners/services.ps1` | Running third-party services |
| `scanners/events.ps1` | System log errors (7 days) and storage-stack warnings |
| `scanners/junk.ps1` | Sizes of safely-cleanable locations (slow — allow a few minutes) |

### Phase 2 — Diagnose and report

Interpret with these heuristics (adjust with judgment, and say why in the report):

- **Memory pressure (usually the #1 real-world bottleneck):** free RAM below
  ~15% of total, commit above ~80%, page file peak above ~25% of RAM, or a large
  "Memory Compression" working set. Attribute it: use process *groups* — a
  browser or Electron app's true footprint is its group total, not one PID.
- **Startup bloat:** more than ~10 enabled entries, or game launchers /
  updaters / rarely-used apps among them. Cross-reference with the process
  groups to show what each entry costs while running.
- **Uptime:** more than ~7 days compounds memory pressure; recommend a reboot.
- **Disk:** any volume below ~15% free (critical below 10%), health status not
  "Healthy" (critical — recommend immediate backup), page file on a nearly-full
  volume. Storage events (e.g. stornvme id 129) at low counts are watch items;
  recurring counts are red flags.
- **CPU:** sustained high load matters; a momentary WmiPrvSE spike from the
  scan itself does not.

Report structure (write it in the user's language; lead with the verdict):

```
一句話總結 / one-line verdict
🔴 Critical findings (each: what, evidence numbers, why it hurts)
🟡 Moderate findings
🟢 Healthy / watch items
建議的處理順序 / recommended fix order, by impact
```

### Phase 3 — Get approval (checkbox menu)

Turn every fixable finding into a selectable option and let the user tick
exactly what to fix — never a wall of text they must answer in prose. When the
AskUserQuestion tool is available, use it with `multiSelect: true`: each
option's label is one concrete fix ("Disable Steam autostart"), and its
description states the expected impact and the undo path. Group related fixes
into one question (e.g. all startup entries together); if a group has more
than four candidates, lead with the highest-impact four and offer the rest in
a follow-up question. Only whitelisted actions belong in the menu — findings
that need manual work (service changes, uninstalls, hardware upgrades) go in a
separate "manual suggestions" list, clearly marked as not automated.

Without AskUserQuestion, print a numbered menu and wait for the user's picks.

Do not fix in the same turn as the report unless the user already explicitly
asked for fixes. Approval is exactly the ticked items: fix those, nothing more,
and a selection today does not authorize the same fix tomorrow.

### Phase 4 — Fix (whitelisted actions only)

**`actions/disable-startup.ps1 -Name <entry>[,<entry>] [-Scope HKCU|HKLM]`**
Backs up the Run and StartupApproved keys as .reg files (to
`Documents\pc-steward-backups\<timestamp>` by default), then marks entries
disabled exactly like Task Manager's Disable button. Nothing is deleted; the
app itself is untouched and can still be opened manually.

Selection rules — the goal is cutting waste, not breaking the user's setup:

- Good candidates: game launchers, updaters, chat/collab apps the user can open
  on demand, vendor helpers (Bing/Edge auto-launch and similar).
- Never disable (script also refuses): Windows security entries.
- Ask before touching: cloud-sync clients (OneDrive, Dropbox…), input-device
  utilities, and anything that looks like the user's own automation (custom
  .vbs/.bat/bot scripts in startup folders) — those exist on purpose.
- HKLM entries need an elevated PowerShell. Non-elevated runs fail cleanly with
  instructions; relaunch elevated via
  `Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File <script> -Name <n> -Scope HKLM'`
  and warn the user a UAC prompt will appear before triggering it.

**`actions/restore-startup.ps1 -BackupDir <dir>`** — undo: re-imports the .reg
backups from a previous run.

### Phase 5 — Verify and hand back

Re-run `scanners/startup.ps1` to confirm the new states. Then tell the user:
what changed, where the backup lives, how to undo (restore script or
double-clicking the .reg files, or Task Manager → Startup apps → Enable), and
that effects apply from the next boot — if uptime was long, now is the moment
to suggest that reboot.

## Out of scope for this skill (say so rather than improvise)

Killing running processes, deleting files, editing services, or registry
changes beyond the StartupApproved mechanism. If the user asks for these,
explain what you'd recommend and let them decide how to proceed manually.
