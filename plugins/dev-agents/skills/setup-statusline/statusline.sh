#!/usr/bin/env bash
# Claude Code status line: model | folder (branch) | session limit | weekly limit
exec node -e '
const { execFileSync } = require("child_process");
const path = require("path");

let j = {};
try { j = JSON.parse(require("fs").readFileSync(0, "utf8")); } catch {}

const c = { reset: "\x1b[0m", dim: "\x1b[2m", cyan: "\x1b[36m", blue: "\x1b[34m",
            magenta: "\x1b[35m", green: "\x1b[32m", yellow: "\x1b[33m", red: "\x1b[31m" };
const sep = ` ${c.dim}|${c.reset} `;

const model = (j.model && j.model.display_name) || "?";
const dir = (j.workspace && j.workspace.current_dir) || j.cwd || process.cwd();

let branch = "";
try {
  branch = execFileSync("git", ["-C", dir, "branch", "--show-current"],
    { stdio: ["ignore", "pipe", "ignore"], timeout: 1000 }).toString().trim();
} catch {}

function limit(label, l, weekly) {
  if (!l || l.used_percentage == null) return `${c.dim}${label} n/a${c.reset}`;
  const p = Math.round(l.used_percentage);
  const col = p >= 80 ? c.red : p >= 50 ? c.yellow : c.green;
  let reset = "";
  if (l.resets_at) {
    const d = new Date(l.resets_at * 1000);
    // Fixed UTC-3, 24-hour clock (00:00–23:59). Note: "Etc/GMT+3" means UTC-3 (POSIX sign is inverted).
    const tz = "Etc/GMT+3";
    const hm = d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hourCycle: "h23", timeZone: tz });
    reset = weekly ? `${d.toLocaleDateString("en-US", { weekday: "short", timeZone: tz })} ${hm}` : hm;
    reset = ` ${c.dim}↻ ${reset}${c.reset}`;
  }
  return `${label} ${col}${p}%${c.reset}${reset}`;
}

const rl = j.rate_limits || {};
const parts = [
  `${c.cyan}${model}${c.reset}`,
  `${c.blue}${path.basename(dir)}${c.reset}` + (branch ? ` ${c.magenta}(${branch})${c.reset}` : ""),
  limit("session", rl.five_hour, false),
  limit("week", rl.seven_day, true),
];
process.stdout.write(parts.join(sep));
'
