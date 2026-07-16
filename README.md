# pc-steward

**An AI PC health steward for Windows — it diagnoses *your* machine with evidence, explains what it found in plain language, and fixes only what you approve. Every change is reversible.**

[繁體中文說明](README.zh-TW.md)

## Why another PC tool?

Existing Windows optimizers (WinUtil, Win11Debloat, Sophia Script…) are excellent at applying **generic tweak lists** — the same checkboxes for every machine. pc-steward takes the opposite approach: it lets an AI assistant **look at what is actually happening on your PC** — memory pressure, page file thrashing, which apps hold how much RAM, what starts at boot, disk health, error logs — and reason about *your* bottleneck before recommending anything.

The result reads like a doctor's report, not a settings checklist:

> 🔴 **Memory pressure is your main bottleneck.** 15.2 GB total, 1.7 GB free, commit at 82%. Page file peaked at 5.4 GB — data is being swapped to disk, which is why window switching stutters. The biggest holders: Discord's 6 processes (744 MB), Chrome's 24 processes (1.1 GB)… and 20+ apps launch at boot.

## Safety by design

Letting an AI touch your system settings requires trust. pc-steward earns it structurally, not with promises:

1. **Scanning is read-only.** The 7 scanner scripts only collect data (JSON out). They cannot modify anything.
2. **Fixes are whitelisted scripts, not free-form commands.** The AI may only invoke the bundled action scripts — it never composes its own mutation commands.
3. **Automatic backups before every change.** Actions export the affected registry keys as `.reg` files first. Undo = one script, or just double-click the backup.
4. **Non-destructive mechanisms.** Startup entries are disabled via Windows' own `StartupApproved` mechanism (identical to Task Manager's Disable button). Nothing is deleted; protected security entries are refused at the script level.
5. **Nothing happens without your approval.** Scan → report → *you choose* → fix → verify.

## Installation

The core is agent-agnostic (PowerShell scripts + a plain-markdown operating
manual), with thin adapters per agent host.

### Claude Code

**As a plugin (recommended):**

```
/plugin marketplace add Lother13501350/pc-steward
/plugin install pc-steward
```

**Or manual skill install:** copy `skills/pc-steward/` into your
`~/.claude/skills/` directory.

### OpenAI Codex

```
git clone https://github.com/Lother13501350/pc-steward
cd pc-steward
codex
```

Then just say *"my pc is slow"* — Codex picks up [AGENTS.md](AGENTS.md)
automatically and follows the same workflow and safety rules.

Optional global `/pc-steward` command: copy `adapters/codex/pc-steward.md`
into `~/.codex/prompts/`, edit the `<REPO_PATH>` line inside it once, and
invoke `/pc-steward` from any directory.

### Other agent CLIs (Cursor, Gemini CLI, …)

Any agent that reads `AGENTS.md` works the same way as Codex: clone the repo,
start your agent inside it, and ask about your PC.

Requirements: Windows 10/11 and Windows PowerShell 5.1+ (preinstalled). From
WSL, agents can call `powershell.exe` directly.

## Usage

Just talk to Claude Code:

- *"My laptop feels slow lately, can you check what's wrong?"*
- *"Scan my PC for performance bottlenecks."*
- *"Clean up my startup programs."*
- *"電腦越來越慢，幫我健檢一下"*

Claude will run the scanners, give you a severity-ranked diagnosis with evidence, and propose fixes as a menu. Nothing is changed until you say yes.

## What's in the box

```
skills/pc-steward/
├── SKILL.md                     # the steward's workflow & safety rules
└── scripts/
    ├── scanners/                # read-only, JSON output
    │   ├── system.ps1           # CPU, RAM, uptime, GPU, power plan
    │   ├── processes.ps1        # top RAM/CPU consumers, app groups
    │   ├── startup.ps1          # all autostart entries + enabled/disabled state
    │   ├── disks.ps1            # disk health, free space, page file
    │   ├── services.ps1         # third-party running services
    │   ├── events.ps1           # system errors & storage warnings (7 days)
    │   └── junk.ps1             # cleanable locations (temp, caches, recycle bin)
    └── actions/                 # whitelisted, reversible mutations
        ├── disable-startup.ps1  # Task-Manager-style disable, with .reg backup
        └── restore-startup.ps1  # undo from backup
```

## Roadmap

- **v0.2** — junk cleanup action (temp/caches, with quarantine), MCP server so any MCP client (Claude Desktop etc.) can use pc-steward
- **v0.3** — standalone CLI (bring your own API key), community scanner modules
- **Later** — GUI, macOS/Linux scanners

## Contributing

Issues and PRs welcome. Scanner contributions must be read-only; action contributions must back up state and document their undo path.

## License

[MIT](LICENSE)
