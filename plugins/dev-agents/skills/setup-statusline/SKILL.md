---
name: setup-statusline
description: Install the dev-agents status line, which shows the model, folder, git branch, session (5-hour) usage limit and weekly usage limit with reset times. Use when the user asks to install, set up, update or remove this status line, or invokes /setup-statusline.
---

# Set up the dev-agents status line

This installs the status line below into the user's Claude Code config:

```
Opus 5.5 | my-project (main) | session 11% ↻ 20:10 | week 2% ↻ Sun 05:00
```

- The limit percentages are green below 50%, yellow up to 80%, and red after that.
- Reset times use a 24-hour clock in a fixed **UTC-3** zone (the `tz` constant in the script).
- It needs `node`, plus `git` for the branch.

The script, `statusline.sh`, is in this skill's base directory.

## Install or update

1. **Check what exists.** Read `~/.claude/settings.json`, and `~/.claude/statusline.sh` if it exists.
   - If `statusLine` already points somewhere else, show the user the current command and ask whether to replace it.
   - If `~/.claude/statusline.sh` exists and differs from this skill's copy, show the diff and ask before overwriting.
2. **Ask about the time zone** only if the user mentions one. Otherwise keep UTC-3. To change it, set `tz` to an IANA zone (for example `"America/New_York"` or `"UTC"`). Fixed offsets use inverted POSIX signs: `"Etc/GMT+3"` means UTC-3.
3. **Copy** `statusline.sh` from this skill's directory to `~/.claude/statusline.sh`, then run `chmod +x ~/.claude/statusline.sh`.
4. **Merge** this into `~/.claude/settings.json`, keeping every other key:
   ```json
   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
   ```
5. **Verify:**
   - Check that the settings file is still valid JSON.
   - Run a sample through the script:
     `echo '{"model":{"display_name":"Test"},"workspace":{"current_dir":"'"$PWD"'"},"rate_limits":{"five_hour":{"used_percentage":42,"resets_at":2000000000},"seven_day":{"used_percentage":7,"resets_at":2000000000}}}' | ~/.claude/statusline.sh`
   - It should print one line with all four parts.
6. **Tell the user** it's live. The limits may show `n/a` until Claude's first reply. Usage limits only appear on Claude subscription plans, not API keys.

## Remove

Delete the `statusLine` key from `~/.claude/settings.json`, then ask before deleting `~/.claude/statusline.sh`.
