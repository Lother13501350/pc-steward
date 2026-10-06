# pc-steward

A Windows diagnostic toolkit that gives coding agents structured evidence before a user approves a startup change.

[Traditional Chinese guide](README.zh-TW.md) · [Agent workflow](skills/pc-steward/SKILL.md) · [MIT license](LICENSE)

## Overview and status

pc-steward combines seven read-only PowerShell scanners with an agent operating manual and two startup action scripts. It is intended for a Windows user working with a coding assistant who wants to understand memory, process, startup, disk, service, and event evidence before changing settings.

This is an **experimental toolkit**, version 0.1.0 in the plugin manifest. It has no automated test suite, CI workflow, or benchmark demonstrating performance improvement. It does not run a local model or implement a standalone AI service; reasoning comes from the agent host.

## Implemented behavior

- JSON output for system, processes, startup, disks, services, events, and junk-location scans.
- An evidence-based diagnosis and approval workflow documented for agent hosts.
- Startup disabling for selected `Run` entries in HKCU/HKLM via `StartupApproved`.
- Registry exports before disable actions, refusal when backup fails, and a protected-entry list.
- An undo script that re-imports `.reg` backups.
- Claude Code plugin metadata and an `AGENTS.md` entry point for other coding agents.

## Safety boundaries

Scanning and approval are separate steps. The workflow requires user approval before an agent invokes the bundled action scripts; the PowerShell scripts themselves do not implement an approval UI or independently enforce that conversational approval.

The disable script supports the selected `Run` scope, not every startup location discovered by the scanner. HKLM changes require administrator rights. The protected-name list is specific and is not a complete catalogue of security products.

Restoration re-imports exported keys. If `StartupApproved\Run` did not exist before the disable action, no backup of that absent key is exported, and the restore script does not remove the newly created override. That edge case needs a code fix and Windows regression test before claiming every action is reversible. Retain backups and verify the actual startup state after restoration.

## Getting started

Requirements: Windows 10/11 and Windows PowerShell 5.1+. macOS/Linux are not supported execution targets. From WSL, call the Windows `powershell.exe` executable.

```powershell
git clone https://github.com/Lother13501350/pc-steward.git
cd pc-steward
powershell -NoProfile -ExecutionPolicy Bypass -File skills/pc-steward/scripts/scanners/system.ps1
```

The scanner returns one JSON object. To use an agent, start it inside the repository so it can read [AGENTS.md](AGENTS.md) and [the operating manual](skills/pc-steward/SKILL.md). Follow the agent host's current installation instructions when installing the packaged skill/plugin.

For Claude Code, the repository provides the following plugin installation commands:

```text
/plugin marketplace add Lother13501350/pc-steward
/plugin install pc-steward
```

A manual installation can copy `skills/pc-steward/` into the host's skill directory. No API credentials are embedded in the toolkit; the host handles its own model access.

## Architecture and structure

```text
User request -> agent host -> read-only scanners -> JSON evidence
            -> diagnosis -> user approval -> bundled startup action
            -> registry backups -> verification / restore
```

| Path | Responsibility |
| --- | --- |
| `skills/pc-steward/SKILL.md` | Diagnosis, approval, and recovery workflow. |
| `skills/pc-steward/scripts/scanners/` | Seven Windows evidence collectors. |
| `skills/pc-steward/scripts/actions/` | Startup disable/restore scripts. |
| `.claude-plugin/` | Plugin and marketplace metadata. |
| `AGENTS.md`, `adapters/` | Host integration instructions. |

## Verification and contribution

The portfolio audit reviewed script behavior; it did not run Windows actions on this Mac. Tests should use disposable Windows fixtures for absent/existing registry keys, protected entries, failed exports, scope handling, and restore behavior. The scripts are not a general junk-removal or service-tuning engine.

The engineering work to review is the JSON interface, backup-before-write ordering, failure checks, and limited action surface. Contributions should keep scanners read-only and add a tested undo path for every new action.

## Roadmap

The existing roadmap proposes quarantined junk cleanup, an MCP server, a standalone CLI, community scanners, and later GUI/other-platform support. These are plans, not implemented features.

## License

[MIT](LICENSE).
