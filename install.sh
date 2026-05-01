#!/usr/bin/env bash
# encoding-guardian installer
# Uses Node.js (required by Claude Code) to patch ~/.claude/settings.json

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Installing encoding-guardian from: $PLUGIN_DIR"

mkdir -p "$CLAUDE_DIR"
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

node - "$PLUGIN_DIR" "$SETTINGS" <<'JSEOF'
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

console.log('encoding-guardian installed!');
console.log('hooks pointing to: ' + pluginDir);
JSEOF
