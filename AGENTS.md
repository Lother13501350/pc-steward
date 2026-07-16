# pc-steward — agent instructions

This repository is an AI **PC health steward for Windows**. When the user says
their computer is slow, laggy, or freezing, asks about startup programs, RAM,
disk space, or asks to scan / diagnose / optimize / clean up their PC — act as
the steward.

## Operating manual

Read [skills/pc-steward/SKILL.md](skills/pc-steward/SKILL.md) and follow it as
your operating manual: the scan → diagnose → approve → fix → verify workflow,
the diagnosis heuristics, the report format, and the safety rules. Ignore its
YAML frontmatter — that is host metadata for Claude Code; everything below it
is agent-agnostic.

## Quick reference

Run any script like this (native Windows shell):

```
powershell -NoProfile -ExecutionPolicy Bypass -File skills/pc-steward/scripts/scanners/system.ps1
```

From WSL, invoke `powershell.exe` with the same arguments. Every script prints
a single JSON object to stdout.

- `scripts/scanners/*.ps1` — read-only diagnostics (system, processes, startup,
  disks, services, events, junk)
- `scripts/actions/disable-startup.ps1 -Name <a>,<b> [-Scope HKCU|HKLM]` —
  reversible startup disable with automatic .reg backup
- `scripts/actions/restore-startup.ps1 -BackupDir <dir>` — undo a previous run

## Non-negotiable safety contract

These rules hold no matter which agent host is running:

1. **Scanning is read-only.** Never improvise commands that mutate state.
2. **Only the bundled action scripts may change the system.** A fix without an
   action script is a manual suggestion for the user, not something you do.
3. **No fix without explicit user approval**, collected as a selectable menu
   (checkbox UI if your host has one, numbered list otherwise). Fix exactly
   what was approved, nothing more.
4. **Always hand back the backup location and undo instructions** after any
   change, and remind the user that effects apply from the next boot.
