#!/usr/bin/env bash
# encoding-guardian installer
# Adds hooks directly to ~/.claude/settings.json

set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "Installing encoding-guardian from: $PLUGIN_DIR"

mkdir -p "$CLAUDE_DIR"
[ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

python3 - "$PLUGIN_DIR" "$SETTINGS" <<'PYEOF'
import json, sys, os

plugin_dir = sys.argv[1]
settings_path = sys.argv[2]

with open(settings_path, 'r', encoding='utf-8') as f:
    settings = json.load(f)

hooks = settings.setdefault('hooks', {})

pre_cmd  = f'node "{plugin_dir}/hooks/pre-tool.js"'
post_cmd = f'node "{plugin_dir}/hooks/post-tool.js"'

def is_guardian(entry):
    return any(
        'pre-tool.js'  in h.get('command', '') or
        'post-tool.js' in h.get('command', '')
        for h in entry.get('hooks', [])
    )

def upsert(event, matcher, cmd):
    bucket = hooks.setdefault(event, [])
    # Remove old encoding-guardian entries for this matcher
    hooks[event] = [e for e in bucket if not (e.get('matcher') == matcher and is_guardian(e))]
    hooks[event].append({
        'matcher': matcher,
        'hooks': [{'type': 'command', 'command': cmd, 'timeout': 10}]
    })

upsert('PreToolUse',  'Read',  pre_cmd)
upsert('PreToolUse',  'Edit',  pre_cmd)
upsert('PostToolUse', 'Edit',  post_cmd)
upsert('PostToolUse', 'Write', post_cmd)

with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)

print(f'✓ encoding-guardian installed!')
print(f'  hooks pointing to: {plugin_dir}')
PYEOF
