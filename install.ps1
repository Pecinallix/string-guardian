# encoding-guardian installer for Windows
# Adds hooks directly to %USERPROFILE%\.claude\settings.json

$ErrorActionPreference = 'Stop'

$pluginDir   = $PSScriptRoot
$claudeDir   = "$env:USERPROFILE\.claude"
$settingsPath = "$claudeDir\settings.json"

Write-Host "Installing encoding-guardian from: $pluginDir"

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

if (-not (Test-Path $settingsPath)) {
    '{}' | Out-File -FilePath $settingsPath -Encoding utf8
}

$py = @"
import json, sys

plugin_dir    = sys.argv[1]
settings_path = sys.argv[2]

with open(settings_path, 'r', encoding='utf-8') as f:
    settings = json.load(f)

hooks = settings.setdefault('hooks', {})

pre_cmd  = 'node "' + plugin_dir.replace('\\\\', '\\') + '\\\\hooks\\\\pre-tool.js"'
post_cmd = 'node "' + plugin_dir.replace('\\\\', '\\') + '\\\\hooks\\\\post-tool.js"'

def is_guardian(entry):
    return any(
        'pre-tool.js'  in h.get('command', '') or
        'post-tool.js' in h.get('command', '')
        for h in entry.get('hooks', [])
    )

def upsert(event, matcher, cmd):
    bucket = hooks.setdefault(event, [])
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

print('encoding-guardian installed!')
print('hooks pointing to: ' + plugin_dir)
"@

python -c $py $pluginDir $settingsPath
