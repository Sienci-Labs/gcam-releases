import { createInterface } from 'node:readline';
import { stripVTControlCharacters } from 'node:util';

// Only print fixed text, spec basenames and numeric totals from private output.
let failed = 0;
for await (const raw of createInterface({ input: process.stdin })) {
    const line = stripVTControlCharacters(raw);
    const running = line.match(/^\s*Running:\s+([a-zA-Z0-9_-]+\.cy\.js)\s/);
    if (running) console.log(`Running ${running[1]}`);
    const count = line.match(/^\s*\u2502\s*Failing:\s*(\d+)\s*\u2502\s*$/);
    if (count) failed = Number(count[1]);
    const spec = line.match(/^\s*\u2502\s*Spec Ran:\s*([a-zA-Z0-9_-]+\.cy\.js)\s*\u2502\s*$/);
    if (spec) console.log(`Finished ${spec[1]}: ${failed} failed`);
}
