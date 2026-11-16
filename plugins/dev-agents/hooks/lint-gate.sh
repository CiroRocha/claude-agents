#!/usr/bin/env bash
# Enforces "linter agent runs before code-reviewer agent".
#
#   lint-gate.sh mark   - called by the linter agent when it finishes; records a
#                         fingerprint of the repo's current working tree.
#   lint-gate.sh check  - PreToolUse hook on the Agent tool; blocks code-reviewer
#                         unless the tree still matches the last lint fingerprint.

STATE_DIR="$HOME/.claude/state/lint-gate"

fingerprint() {
  {
    git rev-parse HEAD 2>/dev/null
    git diff HEAD --binary 2>/dev/null
    git ls-files --others --exclude-standard -z | xargs -0 -r sha1sum 2>/dev/null
  } | sha1sum | cut -d' ' -f1
}

marker_for() { echo "$STATE_DIR/$(printf '%s' "$1" | sha1sum | cut -d' ' -f1)"; }

case "$1" in
  mark)
    root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "lint-gate: not in a git repo, nothing to mark"; exit 0; }
    mkdir -p "$STATE_DIR"
    (cd "$root" && fingerprint) > "$(marker_for "$root")"
    echo "lint-gate: marked $root as linted"
    ;;

  check)
    # Keep a copy at a fixed path so the linter agent can call "mark" without
    # knowing where the plugin is installed.
    mkdir -p "$STATE_DIR"
    cp -f "$0" "$STATE_DIR/lint-gate.sh" 2>/dev/null && chmod +x "$STATE_DIR/lint-gate.sh"
    read -r agent cwd < <(node -e '
      let d = "";
      process.stdin.on("data", c => d += c).on("end", () => {
        try {
          const j = JSON.parse(d);
          const t = (j.tool_input && j.tool_input.subagent_type) || "-";
          process.stdout.write(t + " " + (j.cwd || process.cwd()));
        } catch { process.stdout.write("- -"); }
      });
    ')
    # Plugin agents may be namespaced, e.g. "dev-agents:code-reviewer".
    case "$agent" in code-reviewer|*:code-reviewer) ;; *) exit 0 ;; esac
    root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null) || exit 0
    marker=$(marker_for "$root")
    if [ ! -f "$marker" ]; then
      echo "Blocked: run the 'linter' agent on these changes first, wait for it to finish, then call code-reviewer and include the linter's report in its prompt." >&2
      exit 2
    fi
    if [ "$(cat "$marker")" != "$(cd "$root" && fingerprint)" ]; then
      echo "Blocked: the code changed since the linter last ran. Run the 'linter' agent again, wait for it to finish, then call code-reviewer with its report." >&2
      exit 2
    fi
    exit 0
    ;;

  *)
    echo "usage: lint-gate.sh mark|check" >&2; exit 1 ;;
esac
