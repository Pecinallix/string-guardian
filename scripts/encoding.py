#!/usr/bin/env python3
"""
encoding-guardian: deteccao e conversao de encoding de arquivos.
Comandos:
  detect <filepath>                -> imprime o encoding detectado
  to-utf8 <filepath> <encoding>   -> converte arquivo para UTF-8 (in-place atomico)
  from-utf8 <filepath> <encoding> -> converte arquivo de UTF-8 para encoding (in-place atomico)
"""
import sys
import os


def detect_encoding(filepath):
    try:
        with open(filepath, 'rb') as f:
            raw = f.read()
    except (IOError, OSError) as e:
        print(f'encoding-guardian: cannot read {filepath}: {e}', file=sys.stderr)
        sys.exit(1)

    if not raw:
        return 'utf-8'

    # BOM detection
    if raw[:3] == b'\xef\xbb\xbf':
        return 'utf-8-sig'
    if raw[:4] == b'\xff\xfe\x00\x00':
        return 'utf-32-le'
    if raw[:4] == b'\x00\x00\xfe\xff':
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

    # Bytes 0x80-0x9F sao caracteres validos em cp1252 mas indefinidos em latin-1
    # Se tiver algum deles, e Windows-1252
    win1252_specific = set(range(0x80, 0xA0))
    if any(b in win1252_specific for b in raw):
        return 'cp1252'

    # Bytes acima de 0x7F sem bytes 0x80-0x9F -> latin-1
    if any(b > 0x7F for b in raw):
        return 'latin-1'

    return 'utf-8'  # ASCII puro


def _atomic_write(filepath, data):
    """Escreve data em filepath atomicamente via arquivo temporario."""
    tmp = filepath + '.encoding-guardian.tmp'
    try:
        with open(tmp, 'wb') as f:
            f.write(data)
        os.replace(tmp, filepath)
    except Exception as e:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise e


def to_utf8(filepath, source_encoding):
    """Converte arquivo de source_encoding para UTF-8 (in-place atomico)."""
    with open(filepath, 'rb') as f:
        raw = f.read()

    if source_encoding == 'utf-8-sig' and raw[:3] == b'\xef\xbb\xbf':
        raw = raw[3:]
        source_encoding = 'utf-8'

    try:
        content = raw.decode(source_encoding, errors='strict')
    except (UnicodeDecodeError, LookupError) as e:
        print(f'encoding-guardian: failed to decode {filepath} as {source_encoding}: {e}', file=sys.stderr)
        sys.exit(1)

    try:
        _atomic_write(filepath, content.encode('utf-8'))
    except Exception as e:
        print(f'encoding-guardian: failed to write {filepath}: {e}', file=sys.stderr)
        sys.exit(1)


def from_utf8(filepath, target_encoding):
    """Converte arquivo de UTF-8 para target_encoding (in-place atomico)."""
    with open(filepath, 'rb') as f:
        raw = f.read()

    try:
        content = raw.decode('utf-8', errors='strict')
    except UnicodeDecodeError as e:
        print(f'encoding-guardian: {filepath} is not valid UTF-8: {e}', file=sys.stderr)
        sys.exit(1)

    try:
        encoded = content.encode(target_encoding, errors='strict')
    except (UnicodeEncodeError, LookupError) as e:
        print(f'encoding-guardian: failed to encode {filepath} as {target_encoding}: {e}', file=sys.stderr)
        sys.exit(1)

    try:
        _atomic_write(filepath, encoded)
    except Exception as e:
        print(f'encoding-guardian: failed to write {filepath}: {e}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('uso: encoding.py <detect|to-utf8|from-utf8> <filepath> [encoding]', file=sys.stderr)
        sys.exit(1)

    cmd = sys.argv[1]
    fp  = sys.argv[2]

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
