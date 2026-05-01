'use strict';
/**
 * PostToolUse: Edit | Write
 * - Após Claude salvar o arquivo (agora em UTF-8), restaura o encoding original
 * - Remove o arquivo do mapa após restaurar
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
  const map = shared.readMap();
  const origEncoding = map[abs];

  if (!origEncoding) return process.exit(0); // Não está no mapa → era UTF-8, nada a fazer

  // Arquivo foi deletado? Limpa o mapa
  if (!fs.existsSync(abs)) {
    delete map[abs];
    shared.writeMap(map);
    return process.exit(0);
  }

  // Restaura encoding original
  const ok = pyConvert('from-utf8', abs, origEncoding);

  if (ok) {
    delete map[abs];
    shared.writeMap(map);
    emit(`[encoding-guardian] ${path.basename(abs)}: encoding restaurado para ${origEncoding}.`);
  }

  process.exit(0);
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
