'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');

const CLAUDE_DIR = path.join(os.homedir(), '.claude');
const MAP_FILE = path.join(CLAUDE_DIR, '.encoding-guardian-map.json');

function readMap() {
  try {
    if (!fs.existsSync(MAP_FILE)) return {};
    const raw = fs.readFileSync(MAP_FILE, 'utf8');
    return JSON.parse(raw) || {};
  } catch {
    return {};
  }
}

function writeMap(map) {
  try {
    if (!fs.existsSync(CLAUDE_DIR)) {
      fs.mkdirSync(CLAUDE_DIR, { recursive: true });
    }
    fs.writeFileSync(MAP_FILE, JSON.stringify(map, null, 2), 'utf8');
  } catch {
    // Falha silenciosa — nunca bloquear o fluxo por causa do mapa
  }
}

// Extensões que são inequivocamente texto
const TEXT_EXTENSIONS = new Set([
  '.txt', '.js', '.mjs', '.cjs', '.ts', '.tsx', '.jsx',
  '.py', '.php', '.rb', '.java', '.c', '.cpp', '.h', '.cs', '.go', '.rs',
  '.html', '.htm', '.css', '.scss', '.less', '.sass',
  '.json', '.xml', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf', '.env',
  '.md', '.csv', '.sql', '.sh', '.bat', '.ps1', '.vue', '.svelte', '.log',
  '.htaccess', '.gitignore', '.editorconfig',
]);

function isTextFile(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (TEXT_EXTENSIONS.has(ext)) return true;

  // Sem extensão: amostra os primeiros 512 bytes em busca de bytes nulos (binário)
  if (!ext) {
    try {
      const buf = fs.readFileSync(filePath).slice(0, 512);
      for (const byte of buf) {
        if (byte === 0) return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  return false;
}

module.exports = { readMap, writeMap, MAP_FILE, isTextFile };
