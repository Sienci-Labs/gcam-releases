import { readFileSync } from 'node:fs';
import { stripVTControlCharacters } from 'node:util';

// Public logs may contain only spec basenames, line numbers and fixed categories.
const lines = stripVTControlCharacters(readFileSync(process.argv[2], 'utf8')).split(/\r?\n/);
let currentSpec = '';
let failing = 0;
let reported = 0;
let category = '';
let located = false;
for (const line of lines) {
    for (const code of ['STEP_READER_UNAVAILABLE', 'STEP_IMPORT_TIMEOUT', 'STEP_IMPORT_INVALID', 'STEP_IMPORT_STILL_READING', 'STEP_IMPORT_NETWORK_ERROR', 'STEP_IMPORT_WASM_ERROR', 'STEP_IMPORT_GENERIC_ERROR', 'STEP_IMPORT_OTHER_STATUS', 'STEP_IMPORT_OTHER_DIALOG', 'STEP_IMPORT_NO_STATUS']) {
        if (line.includes(code)) console.log(`  STEP diagnostic: ${code}`);
    }
    const running = line.match(/^\s*Running:\s+([a-zA-Z0-9_-]+\.cy\.js)\s/);
    if (running) currentSpec = running[1];
    if (/^\s*(?:AssertionError|CypressError|TypeError|Error):/.test(line) ||
        /following error originated from your application code/i.test(line)) {
        category = /Timed out|Timed out retrying/i.test(line) ? 'timeout' :
            /not visible|hidden|covered|not actionable/i.test(line) ? 'not actionable' :
            /AssertionError/.test(line) ? 'assertion' : 'error';
        located = false;
    }
    const location = line.match(/cypress\/(e2e|support)\/([a-zA-Z0-9_.-]+\.js):(\d+):\d+/);
    if (category && !located && location && (location[1] === 'support' || location[2] === currentSpec)) {
        const file = location[1] === 'support' ? location[2] : currentSpec;
        console.log(`  ${file}:${location[3]} — ${category}`);
        located = true;
    }
    const count = line.match(/^\s*\u2502\s*Failing:\s*(\d+)\s*\u2502\s*$/);
    if (count) failing = Number(count[1]);
    const spec = line.match(/^\s*\u2502\s*Spec Ran:\s*([a-zA-Z0-9_-]+\.cy\.js)\s*\u2502\s*$/);
    if (spec && failing > 0) {
        console.log(`${spec[1]}: ${failing} failing test(s)`);
        reported++;
    }
    if (spec) { failing = 0; category = ''; }
}
if (!reported) console.log('Cypress did not produce a failed-spec summary. Check browser or test-server startup locally.');
