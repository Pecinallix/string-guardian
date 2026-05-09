#!/usr/bin/env bash
# string-guardian installer
# Supports: Claude Code, Codex CLI

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Checks ---
if ! command -v node &> /dev/null; then
  echo "ERROR: Node.js is required but was not found in PATH."
  echo "Install it from https://nodejs.org and try again."
  exit 1
fi

install_claude() {
  local CLAUDE_DIR="$HOME/.claude"
  local SETTINGS="$CLAUDE_DIR/settings.json"

  echo "  Installing for Claude Code..."
  mkdir -p "$CLAUDE_DIR"
  [ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

  if node - "$PLUGIN_DIR" "$SETTINGS" <<'JSEOF'
const fs   = require('fs');
const path = require('path');

const pluginDir    = process.argv[2];
const settingsPath = process.argv[3];

let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}

if (!settings.hooks) settings.hooks = {};
const hooks = settings.hooks;

const preCmd  = `node "${pluginDir}/hooks/pre-tool.js"`;
const postCmd = `node "${pluginDir}/hooks/post-tool.js"`;

function isGuardian(entry) {
  return (entry.hooks || []).some(h =>
    (h.command || '').includes('pre-tool.js') ||
    (h.command || '').includes('post-tool.js')
  );
}

function upsert(event, matcher, cmd) {
  if (!hooks[event]) hooks[event] = [];
  hooks[event] = hooks[event].filter(e => !(e.matcher === matcher && isGuardian(e)));
  hooks[event].push({ matcher, hooks: [{ type: 'command', command: cmd, timeout: 10 }] });
}

upsert('PreToolUse',  'Read',  preCmd);
upsert('PreToolUse',  'Edit',  preCmd);
upsert('PostToolUse', 'Edit',  postCmd);
upsert('PostToolUse', 'Write', postCmd);

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2), 'utf8');
console.log('  Claude Code: hooks registered in ' + settingsPath);
JSEOF
  then
    : # success
  else
    echo "  WARNING: Claude Code install failed (could not patch settings.json)."
  fi
}

install_codex() {
  local CODEX_DIR="$HOME/.codex"
  local HOOKS_FILE="$CODEX_DIR/hooks.json"

  echo "  Installing for Codex CLI..."
  mkdir -p "$CODEX_DIR"

  if node - "$PLUGIN_DIR" "$HOOKS_FILE" <<'JSEOF'
const fs   = require('fs');
const path = require('path');

const pluginDir  = process.argv[2];
const hooksPath  = process.argv[3];
const sessionCmd = `node "${pluginDir}/hooks/codex-session.js"`;

let config = { hooks: {} };
try { config = JSON.parse(fs.readFileSync(hooksPath, 'utf8')); } catch {}
if (!config.hooks) config.hooks = {};
if (!config.hooks.SessionStart) config.hooks.SessionStart = [];

config.hooks.SessionStart = config.hooks.SessionStart.filter(e =>
  !(e.hooks || []).some(h => (h.command || '').includes('codex-session.js'))
);

config.hooks.SessionStart.push({
  matcher: 'startup|resume',
  hooks: [{ type: 'command', command: sessionCmd, timeout: 5, statusMessage: 'Loading string-guardian...' }]
});

fs.writeFileSync(hooksPath, JSON.stringify(config, null, 2), 'utf8');
console.log('  Codex: hooks registered in ' + hooksPath);
JSEOF
  then
    : # success
  else
    echo "  WARNING: Codex install failed (could not patch ~/.codex/hooks.json)."
  fi
}

echo "string-guardian installer"
echo "========================="
echo "Plugin dir: $PLUGIN_DIR"
echo ""

install_claude

if command -v codex &> /dev/null; then
  install_codex
else
  echo "  Codex CLI not found, skipping (install codex and re-run to add support)"
fi

echo ""
echo "Done! string-guardian is active."
echo "Restart Claude Code / Codex to apply changes."
