import { readFileSync } from 'node:fs';
import { stripVTControlCharacters } from 'node:util';

// Emit only spec basenames and numeric counts. Raw output can contain private data.
const lines = stripVTControlCharacters(readFileSync(process.argv[2], 'utf8')).split(/\r?\n/);
let failing = 0;
let reported = 0;
for (const line of lines) {
    const count = line.match(/^\s*\u2502\s*Failing:\s*(\d+)\s*\u2502\s*$/);
    if (count) failing = Number(count[1]);

    const spec = line.match(/^\s*\u2502\s*Spec Ran:\s*([a-zA-Z0-9_-]+\.cy\.js)\s*\u2502\s*$/);
    if (spec && failing > 0) {
        console.log(`${spec[1]}: ${failing} failing test(s)`);
        reported++;
    }
    if (spec) failing = 0;
}
if (!reported) {
    console.log('Cypress did not produce a failed-spec summary. Check browser or test-server startup locally.');
}
