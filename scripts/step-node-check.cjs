const fs = require('node:fs');
const { performance } = require('node:perf_hooks');

(async () => {
    const start = performance.now();
    try {
        const initialize = require(process.cwd() + '/node_modules/occt-import-js');
        const kernel = await initialize();
        const bytes = fs.readFileSync('cypress/fixtures/engineering-plate.step');
        const result = kernel.ReadStepFile(bytes, {
            linearUnit: 'millimeter',
            linearDeflectionType: 'absolute_value',
            linearDeflection: 0.02,
            angularDeflection: 0.15,
        });
        if (!result.success || !result.meshes?.length) throw new Error();
        fs.writeFileSync(process.env.STEP_RESULT_FILE, `STEP_NODE_PASSED ${Math.round(performance.now() - start)}ms\n`);
    } catch {
        fs.writeFileSync(process.env.STEP_RESULT_FILE, 'STEP_NODE_FAILED\n');
        process.exitCode = 1;
    }
})();
