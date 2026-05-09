'use strict';
const path = require('path');

// Escape backticks and $() to prevent shell injection if path contains special chars
const scriptPath = path.join(__dirname, '..', 'scripts', 'encoding.py')
  .replace(/\\/g, '/')
  .replace(/[`$!]/g, '\\$&');

const instructions = `STRING GUARDIAN ACTIVE.
When reading or editing any file that may contain accented characters (e.g. PHP, Python, JS, text files):

BEFORE reading/editing a file:
  1. Run: python "${scriptPath}" detect <file_path>
  2. If result is NOT "utf-8" or "ascii":
     Run: python "${scriptPath}" to-utf8 <file_path> <detected_encoding>
  3. Now read/edit the file normally.

AFTER saving the file:
  Run: python "${scriptPath}" from-utf8 <file_path> <original_encoding>

UTF-8 and ASCII files: skip all steps.
This preserves cp1252/latin-1 files and prevents corruption of accented characters.`;

process.stdout.write(instructions);