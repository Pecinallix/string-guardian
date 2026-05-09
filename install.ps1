# string-guardian installer for Windows
# Supports: Claude Code, Codex CLI

$ErrorActionPreference = 'Stop'
$pluginDir = $PSScriptRoot

Write-Host "string-guardian installer"
Write-Host "========================="
Write-Host "Plugin dir: $pluginDir"
Write-Host ""

# --- Claude Code ---
Write-Host "  Installing for Claude Code..."
$claudeDir    = "$env:USERPROFILE\.claude"
$settingsPath = "$claudeDir\settings.json"

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
if (-not (Test-Path $settingsPath)) {
    '{}' | Out-File -FilePath $settingsPath -Encoding utf8
}

$jsClaude = @'
const fs = require('fs');
const pluginDir    = process.argv[2];
const settingsPath = process.argv[3];

let settings = {};
try { settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8')); } catch {}

if (!settings.hooks) settings.hooks = {};
const hooks = settings.hooks;

const preCmd  = `node "${pluginDir}\\hooks\\pre-tool.js"`;
const postCmd = `node "${pluginDir}\\hooks\\post-tool.js"`;

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
'@

node -e $jsClaude $pluginDir $settingsPath

# --- Codex CLI ---
if (Get-Command codex -ErrorAction SilentlyContinue) {
    Write-Host "  Installing for Codex CLI..."
    $codexDir  = "$env:USERPROFILE\.codex"
    $hooksPath = "$codexDir\hooks.json"

    New-Item -ItemType Directory -Force -Path $codexDir | Out-Null

    $jsCodex = @'
const fs = require('fs');
const pluginDir = process.argv[2];
const hooksPath = process.argv[3];
const sessionCmd = `node "${pluginDir}\\hooks\\codex-session.js"`;

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
'@

    node -e $jsCodex $pluginDir $hooksPath
} else {
    Write-Host "  Codex CLI not found, skipping (install codex and re-run to add support)"
}

Write-Host ""
Write-Host "Done! string-guardian is active."
Write-Host "Restart Claude Code / Codex to apply changes."