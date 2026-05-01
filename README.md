<p align="center">
  <img width="154" height="129" alt="stringGuardian" src="https://github.com/user-attachments/assets/96b7a49f-edbf-4a48-b063-5a9a89fc1dd7" />
</p>

<h1 align="center">string-guardian</h1>

<p align="center">
  <strong>never corrupt a &atilde; again</strong>
</p>

<p align="center">
  <a href="https://github.com/Pecinallix/string-guardian/stargazers"><img src="https://img.shields.io/github/stars/Pecinallix/string-guardian?style=flat&color=blue" alt="Stars"></a>
  <a href="https://github.com/Pecinallix/string-guardian/commits/main"><img src="https://img.shields.io/github/last-commit/Pecinallix/string-guardian?style=flat" alt="Last Commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Pecinallix/string-guardian?style=flat" alt="License"></a>
</p>

<p align="center">
  <a href="#the-problem">Problem</a> &nbsp;&bull;&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;&bull;&nbsp;
  <a href="#install">Install</a> &nbsp;&bull;&nbsp;
  <a href="#supported-encodings">Encodings</a> &nbsp;&bull;&nbsp;
  <a href="#troubleshooting">Troubleshooting</a>
</p>

---

A [Claude Code](https://claude.ai/code) plugin that automatically detects and preserves file encoding when editing files with accented characters -- `a~`, `c,`, `a`, `e'`, `n~`, `u"`, and more. No configuration. No manual steps. It just works.

## The Problem

When Claude edits a file encoded in Windows-1252 or Latin-1, it reads and writes UTF-8 -- silently corrupting every accented character.

<table>
<tr>
<td width="50%">

### [x] Without string-guardian

```php
// Before edit (cp1252 on disk)
$nome = "Andre";
echo "Ola, " . $nome;
// Autor: Joao
```

```php
// After Claude edits (corruption)
$nome = "AndrÃƒÂ©";
echo "OlÃƒÂ¡, " . $nome;
// Autor: JoÃƒÂ£o
```

</td>
<td width="50%">

### [ok] With string-guardian

```php
// Before edit (cp1252 on disk)
$nome = "Andre";
echo "Ola, " . $nome;
// Autor: Joao
```

```php
// After Claude edits (preserved)
$nome = "Andre";  // <- new line added
echo "Ola, " . $nome;
// Autor: Joao
```

</td>
</tr>
</table>

**Same edit. Zero corruption. Encoding preserved.**

```
+------------------------------------------+
|  ACCENTED CHARS PRESERVED   [========] 100% |
|  ORIGINAL ENCODING KEPT     [========] 100% |
|  CONFIGURATION NEEDED       [        ]   0  |
|  FILES SILENTLY CORRUPTED   [        ]   0  |
+------------------------------------------+
```

- **Transparent** -- hooks fire automatically before and after every edit
- **Zero config** -- detects encoding on the fly, no `.editorconfig` needed
- **Non-destructive** -- UTF-8 files are detected and left completely untouched
- **No dependencies** -- pure Python stdlib + Node.js (already in Claude Code)

---

## How it works

```
1. Claude wants to edit arquivo.php  (cp1252 on disk)
         |
         v
2. [string-guardian] detects cp1252, converts to UTF-8 in-place
         |
         v
3. Claude reads and edits  (sees correct a~ c, a e')
         |
         v
4. Claude saves the file (UTF-8)
         |
         v
5. [string-guardian] restores the file back to cp1252
         |
         v
6. File on disk: correct content, original encoding preserved
```

The whole process is invisible. No temp files, no copies, no side effects.

---

## Supported encodings

| Encoding | Common in |
|---|---|
| `cp1252` / Windows-1252 | Windows (PT, ES, FR, DE, IT...) |
| `latin-1` / ISO-8859-1 | Legacy Linux/Unix, older web projects |
| `utf-8-sig` (UTF-8 with BOM) | Windows Notepad, some editors |
| `utf-16-le` / `utf-16-be` | Windows APIs, some XML files |

UTF-8 files are detected and left completely untouched.

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- Node.js (already required by Claude Code)
- Python 3 (`python3` or `py` in PATH)

---

## Install

### Mac / Linux / Git Bash

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

The installer writes the hooks directly to `~/.claude/settings.json` pointing to the cloned folder. The plugin activates automatically on every Claude Code session after that.

> **Note:** The plugin won't appear in `claude plugin list` -- that command only shows marketplace plugins. To verify the installation:
>
> ```bash
> grep -A2 "pre-tool\|post-tool" ~/.claude/settings.json
> ```

---

## Uninstall

Remove the `pre-tool.js` and `post-tool.js` hook entries from `~/.claude/settings.json`, then delete the cloned folder.

---

## How encoding detection works

The detection uses a layered heuristic -- no external libraries required:

1. **BOM check** -- UTF-8 BOM, UTF-16 LE/BE, UTF-32 -> exact match
2. **UTF-8 strict decode** -- if all bytes are valid UTF-8 sequences -> `utf-8`
3. **Windows-1252 specific bytes** -- bytes `0x80-0x9F` only exist in cp1252 -> `cp1252`
4. **Any high byte** -- remaining non-ASCII without BOM -> `cp1252` (safe superset of Latin-1)
5. **Pure ASCII** -> treated as `utf-8` (compatible)

---

## Project structure

```
string-guardian/
+-- .claude-plugin/
|   +-- plugin.json        # hook declarations (PreToolUse + PostToolUse)
+-- hooks/
|   +-- pre-tool.js        # detects encoding, converts to UTF-8 before Claude reads/edits
|   +-- post-tool.js       # restores original encoding after Claude saves
|   +-- shared.js          # encoding map (~/.claude/.encoding-guardian-map.json)
+-- scripts/
|   +-- encoding.py        # detect / to-utf8 / from-utf8  (pure Python stdlib)
+-- skills/encoding-guardian/
|   +-- SKILL.md
+-- install.sh             # installer for Mac/Linux/Git Bash
+-- install.ps1            # installer for Windows PowerShell
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

Issues and PRs welcome. The detection logic lives in `scripts/encoding.py` -- easy to extend with new encodings.

---

## License

MIT