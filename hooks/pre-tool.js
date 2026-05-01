'use strict';
/**
 * PreToolUse: Read | Edit
 * - Detecta o encoding do arquivo alvo
 * - Se não for UTF-8, converte para UTF-8 in-place e registra no mapa
 * - Claude passa a trabalhar com UTF-8 transparentemente
 */
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const shared = require('./shared');

let buf = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { buf += chunk; });
process.stdin.on('end', () => {
  try {
    run(JSON.parse(buf));
  } catch {
    process.exit(0);
  }
});

function run(input) {
  const ti = input.tool_input || {};
  const filePath = ti.file_path;

  if (!filePath) return process.exit(0);

  const abs = path.resolve(filePath);

  if (!fs.existsSync(abs)) return process.exit(0);
  if (!shared.isTextFile(abs)) return process.exit(0);

  const map = shared.readMap();

  // Já está no mapa → arquivo já convertido para UTF-8, apenas informa
  if (map[abs]) {
    emit(`[encoding-guardian] ${path.basename(abs)}: em edição como UTF-8 (original: ${map[abs]}).`);
    return process.exit(0);
  }

  // Detecta encoding via Python
  const enc = pyDetect(abs);
  if (!enc || enc === 'utf-8' || enc === 'ascii') return process.exit(0);

  // Converte para UTF-8 in-place
  const ok = pyConvert('to-utf8', abs, enc);
  if (!ok) return process.exit(0);

  // Registra no mapa para restauração posterior
  map[abs] = enc;
  shared.writeMap(map);

  emit(`[encoding-guardian] ${path.basename(abs)}: encoding ${enc} detectado. Convertido para UTF-8. Será restaurado após salvar.`);
  process.exit(0);
}

function pyDetect(filePath) {
  const script = path.join(__dirname, '..', 'scripts', 'encoding.py');
  for (const py of ['python', 'python3', 'py']) {
    const r = spawnSync(py, [script, 'detect', filePath], { encoding: 'utf8', timeout: 8000 });
    if (r.error && r.error.code === 'ENOENT') continue;
    if (r.status === 0 && r.stdout) return r.stdout.trim();
  }
  return null;
}

function pyConvert(cmd, filePath, encoding) {
  const script = path.join(__dirname, '..', 'scripts', 'encoding.py');
  for (const py of ['python', 'python3', 'py']) {
    const r = spawnSync(py, [script, cmd, filePath, encoding], { encoding: 'utf8', timeout: 8000 });
    if (r.error && r.error.code === 'ENOENT') continue;
    if (r.status === 0) return true;
    break;
  }
  return false;
}

function emit(msg) {
  process.stdout.write(JSON.stringify({ type: 'system', content: msg }) + '\n');
}
