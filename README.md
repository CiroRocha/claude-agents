# claude-agents

A Claude Code plugin (`dev-agents`) with my development agents.

| Component | Type | What it does |
|---|---|---|
| `/architect` | Skill | Runs a design panel of 1–3 `architect` agents with different lenses. With 2 or more agents they vote on each other's proposals. Presents a recommended design plus ranked alternatives with tradeoffs. |
| `architect` | Agent | A panel member: writes one proposal from its lens and scores rival proposals. Read-only, plus web search. |
| `linter` | Agent | Lints changed files with the project's own linters, applies safe auto-fixes, and reports what's left. |
| `code-reviewer` | Agent | Reviews changes for correctness, security, breaking changes, performance and tests. Read-only. |
| Lint gate | Hook | Blocks `code-reviewer` until `linter` has run on the current state of the code. |
| `/setup-statusline` | Skill | Installs a status line showing the model, folder, git branch, and session and weekly usage limits with reset times (24-hour clock, UTC-3). |

The status line preview:

```
Opus 5.5 | my-project (main) | session 11% ↻ 20:10 | week 2% ↻ Sun 05:00
```

Run `/setup-statusline` once on each computer. It copies the script to `~/.claude/statusline.sh` and enables it in your settings. To use your own time zone, say so, for example `/setup-statusline use America/New_York`.

## Install

```
/plugin marketplace add CiroRocha/claude-agents
/plugin install dev-agents@dev-agents
```

Then restart Claude Code.

## Update

```
/plugin marketplace update dev-agents
```

## Requirements

- `git` and `node`, which the lint gate uses to fingerprint the working tree and parse hook input
- The linters themselves (eslint, ruff, shellcheck and so on). The linter agent never installs anything.

## How the review flow works

1. `linter` lints the changed files, auto-fixes what it safely can, then runs
   `~/.claude/state/lint-gate/lint-gate.sh mark` to record a fingerprint of the working tree.
2. When `code-reviewer` is started, the gate hook compares the current tree to that fingerprint.
   If lint hasn't run, or the code changed since it ran, the gate blocks the review and asks for the linter first.
3. `code-reviewer` gets the lint report in its prompt and skips issues the linter already covered.

Folders that aren't git repos, and all other agents, are never blocked.
