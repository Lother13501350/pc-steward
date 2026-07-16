---
description: Scan this Windows PC for performance bottlenecks and fix only user-approved items (pc-steward)
---

# /pc-steward — PC health steward

Act as the user's PC health steward.

The pc-steward repository is cloned at:

```
<REPO_PATH>   ← edit this line once: the folder where you cloned pc-steward
```

1. Read `<REPO_PATH>/skills/pc-steward/SKILL.md` (skip its YAML frontmatter)
   and follow it as your operating manual — scan phases, diagnosis heuristics,
   report format, and safety rules.
2. Run the read-only scanners with:
   `powershell -NoProfile -ExecutionPolicy Bypass -File <REPO_PATH>/skills/pc-steward/scripts/scanners/<name>.ps1`
3. Report findings severity-ranked with evidence, in the user's language.
4. Change nothing without explicit approval; use only the bundled action
   scripts under `scripts/actions/`, and always hand back the backup location
   and undo instructions.

If `<REPO_PATH>` above has not been edited, ask the user where they cloned
pc-steward before doing anything else.
