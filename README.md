# String-Guardian

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

| Encoding                     | Common in                             |
| ---------------------------- | ------------------------------------- |
| `cp1252` / Windows-1252      | Windows (PT, ES, FR, DE, IT…)       |
| `latin-1` / ISO-8859-1       | Legacy Linux/Unix, older web projects |
| `utf-8-sig` (UTF-8 with BOM) | Windows Notepad, some editors         |
| `utf-16-le` / `utf-16-be`    | Windows APIs, some XML files          |

UTF-8 files are detected and left completely untouched.

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- Node.js (already required by Claude Code)
- Python 3 (`python3` or `py` in PATH) — for encoding detection and conversion

---

## Installation

### Mac / Linux

```bash
git clone https://github.com/Pecinallix/string-guardian
cd string-guardian
bash install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/Pecinallix/string-guardian
cd string-guardian
.\install.ps1
```

### Windows (Git Bash)

```bash
git clone https://github.com/Pecinallix/string-guardian
cd string-guardian
bash install.sh
```

The installer writes the hooks directly to `~/.claude/settings.json` pointing to the cloned folder. The plugin activates automatically on every Claude Code session after that.

> **Note:** The plugin won't appear in `claude plugin list` — that command only shows marketplace plugins. To verify the installation, run:
>
> ```bash
> grep -A2 "pre-tool\|post-tool" ~/.claude/settings.json
> ```

---

## Uninstall

Remove the `pre-tool.js` and `post-tool.js` entries from `~/.claude/settings.json`, then delete the cloned folder.

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
string-guardian/
├── .claude-plugin/
│   └── plugin.json        ↝ hook declarations (PreToolUse + PostToolUse)
├── hooks/
│   ├── pre-tool.js        ↝ detects encoding, converts to UTF-8 before Claude reads/edits
│   ├── post-tool.js       ↝ restores original encoding after Claude saves
│   └── shared.js          ↝ encoding map (~/.claude/.encoding-guardian-map.json)
├── scripts/
│   └── encoding.py        ↝ detect / to-utf8 / from-utf8  (pure Python stdlib)
├── skills/encoding-guardian/
│   └── SKILL.md
├── install.sh             ↝ installer for Mac/Linux/Git Bash
└── install.ps1            ↝ installer for Windows PowerShell
```

---

## Troubleshooting

**Hooks not firing?**
Run `grep -A2 "pre-tool" ~/.claude/settings.json` to confirm the hooks are registered.

**Python not found?**
Install Python 3 from [python.org](https://www.python.org/downloads/) and ensure it's in your PATH.

**File still corrupted after edit?**
Open an issue with the file extension, OS, and original encoding.

---

## Contributing

Issues and PRs welcome. The detection logic lives in `scripts/encoding.py` — easy to extend with new encodings.

---

## License

MIT
