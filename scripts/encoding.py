#!/usr/bin/env python3
"""
encoding-guardian: detecção e conversão de encoding de arquivos.
Comandos:
  detect <filepath>              → imprime o encoding detectado
  to-utf8 <filepath> <encoding> → converte arquivo para UTF-8 (in-place)
  from-utf8 <filepath> <encoding> → converte arquivo de UTF-8 para encoding (in-place)
"""
import sys
import os


def detect_encoding(filepath):
    try:
        with open(filepath, 'rb') as f:
            raw = f.read()
    except (IOError, OSError):
        return 'utf-8'

    if not raw:
        return 'utf-8'

    # BOM detection — mais confiável que heurística
    if raw[:3] == b'\xef\xbb\xbf':
        return 'utf-8-sig'
    if raw[:4] in (b'\xff\xfe\x00\x00',):
        return 'utf-32-le'
    if raw[:4] in (b'\x00\x00\xfe\xff',):
        return 'utf-32-be'
    if raw[:2] == b'\xff\xfe':
        return 'utf-16-le'
    if raw[:2] == b'\xfe\xff':
        return 'utf-16-be'

    # Tenta UTF-8 estrito
    try:
        raw.decode('utf-8')
        return 'utf-8'
    except UnicodeDecodeError:
        pass

    # Bytes 0x80-0x9F são caracteres válidos em cp1252 mas indefinidos em latin-1
    # Se tiver algum deles, provavelmente é Windows-1252
    win1252_specific = set(range(0x80, 0xA0))
    if any(b in win1252_specific for b in raw):
        return 'cp1252'

    # Qualquer byte acima de 0x7F sem os bytes 0x80-0x9F
    # Usa cp1252 como padrão pois é um superconjunto de latin-1 e é o padrão Windows
    if any(b > 0x7F for b in raw):
        return 'cp1252'

    return 'utf-8'  # ASCII puro — UTF-8 compatível


def to_utf8(filepath, source_encoding):
    """Converte arquivo de source_encoding para UTF-8 (in-place, preserva line endings)."""
    with open(filepath, 'rb') as f:
        raw = f.read()

    # Remove BOM do UTF-8 se presente (não deveria estar aqui, mas por segurança)
    if source_encoding == 'utf-8-sig' and raw[:3] == b'\xef\xbb\xbf':
        raw = raw[3:]
        source_encoding = 'utf-8'

    content = raw.decode(source_encoding, errors='replace')

    with open(filepath, 'wb') as f:
        f.write(content.encode('utf-8'))


def from_utf8(filepath, target_encoding):
    """Converte arquivo de UTF-8 para target_encoding (in-place, preserva line endings)."""
    with open(filepath, 'rb') as f:
        raw = f.read()

    content = raw.decode('utf-8', errors='replace')

    encoded = content.encode(target_encoding, errors='replace')
    with open(filepath, 'wb') as f:
        f.write(encoded)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('uso: encoding.py <detect|to-utf8|from-utf8> <filepath> [encoding]', file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    fp = sys.argv[2]

    if cmd == 'detect':
        print(detect_encoding(fp))

    elif cmd == 'to-utf8':
        if len(sys.argv) < 4:
            sys.exit(1)
        to_utf8(fp, sys.argv[3])

    elif cmd == 'from-utf8':
        if len(sys.argv) < 4:
            sys.exit(1)
        from_utf8(fp, sys.argv[3])

    else:
        sys.exit(1)
