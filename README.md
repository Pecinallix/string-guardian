# encoding-guardian

A Claude Code plugin that automatically detects and preserves file encoding when editing files with accented characters — `ã`, `ç`, `à`, `é`, `ñ`, `ü`, and more.

**The problem:** When Claude edits a file encoded in Windows-1252 (cp1252) or Latin-1, it reads and writes UTF-8 — corrupting every accented character.

**The fix:** This plugin transparently converts non-UTF-8 files to UTF-8 before Claude reads them, then restores the original encoding after saving. No configuration. No manual steps. It just works.

---

## How it works

```
1. Claude wants to edit arquivo.php  (encoded as cp1252 on disk)
         ↓
2. [encoding-guardian] detects cp1252, converts file to UTF-8 in-place
         ↓
3. Claude reads ✓ and edits ✓  (sees correct ã ç à é)
         ↓
4. Claude saves the file (UTF-8)
         ↓
5. [encoding-guardian] restores the file back to cp1252
         ↓
6. File on disk: correct content, original encoding preserved ✓
```

No accents are ever corrupted. The whole process is invisible.

---

## Supported encodings

| Encoding | Common in |
|----------|-----------|
| `cp1252` / Windows-1252 | Windows (PT, ES, FR, DE, IT…) |
| `latin-1` / ISO-8859-1 | Legacy Linux/Unix, older web projects |
| `utf-8-sig` (UTF-8 with BOM) | Windows Notepad, some editors |
| `utf-16-le` / `utf-16-be` | Windows APIs, some XML files |

UTF-8 files are detected and left completely untouched.

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- Python 3 (`python`, `python3`, or `py` in PATH)

---

## Installation

### One-liner (recommended)

```bash
git clone https://github.com/YOUR_USERNAME/encoding-guardian
claude plugin install ./encoding-guardian
```

### Windows (PowerShell)

```powershell
git clone https://github.com/YOUR_USERNAME/encoding-guardian
claude plugin install .\encoding-guardian
```

That's it. The plugin activates automatically for every Claude Code session.

---

## Uninstall

```bash
claude plugin uninstall encoding-guardian
```

---

## How the plugin detects encoding

The detection uses a layered heuristic — no external libraries required:

1. **BOM check** — UTF-8 BOM, UTF-16 LE/BE, UTF-32 → exact match
2. **UTF-8 strict decode** — if all bytes are valid UTF-8 sequences → `utf-8`
3. **Windows-1252 specific bytes** — bytes `0x80–0x9F` only exist in cp1252 → `cp1252`
4. **Any high byte** — remaining non-ASCII without BOM → `cp1252` (safe superset of Latin-1)
5. **Pure ASCII** → treated as `utf-8` (compatible)

---

## Project structure

```
encoding-guardian/
├── .claude-plugin/
│   └── plugin.json        ← hook declarations (PreToolUse + PostToolUse)
├── hooks/
│   ├── pre-tool.js        ← detects encoding, converts to UTF-8 before Claude reads/edits
│   ├── post-tool.js       ← restores original encoding after Claude saves
│   └── shared.js          ← encoding map (~/.claude/.encoding-guardian-map.json)
├── scripts/
│   └── encoding.py        ← detect / to-utf8 / from-utf8  (pure Python stdlib)
└── skills/encoding-guardian/
    └── SKILL.md
```

---

## Troubleshooting

**Plugin doesn't activate?**
Make sure `claude plugin list` shows `encoding-guardian`. If not, re-run `claude plugin install`.

**Python not found?**
Install Python 3 from [python.org](https://www.python.org/downloads/) and ensure it's in your PATH.

**File still corrupted after edit?**
Check that the file path doesn't contain special characters that might confuse the path resolver. Open an issue with the file extension and OS.

---

## Contributing

Issues and PRs welcome. The detection logic lives in `scripts/encoding.py` — easy to extend with new encodings.

---

## License

MIT
