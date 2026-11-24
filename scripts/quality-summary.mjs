import { readFileSync } from 'node:fs';
import { basename } from 'node:path';
import { stripVTControlCharacters } from 'node:util';

// Keep private source, paths, messages and test names out of public logs.
const lines = stripVTControlCharacters(readFileSync(process.argv[2], 'utf8')).split(/\r?\n/);
for (const line of lines) {
    const failed = line.match(/^FAIL\s+([^\s]+\.(?:test|spec)\.[cm]?[jt]sx?)(?:\s|$)/);
    if (failed) console.log(`Failed test file: ${basename(failed[1])}`);
    const summary = line.match(/^\s*(Test Suites|Tests|Snapshots):\s*(\d+ failed,\s*)?(\d+ passed,\s*)?(\d+ skipped,\s*)?\d+ total\s*$/);
    if (summary) console.log(line.trim());
}
