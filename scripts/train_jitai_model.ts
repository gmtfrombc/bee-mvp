// deno run -A scripts/train_jitai_model.ts [path/to/ndjson]
// Simple stub to compute baseline ROC-AUC for JITAI triggers dataset.
// For now, just loads data and outputs counts; real ML training will be added later.

import { readLines } from "https://deno.land/std@0.168.0/io/mod.ts";

const path = Deno.args[0] ?? "jitai_training_sample.ndjson";
let positive = 0, total = 0;
for await (const line of readLines(await Deno.open(path))) {
    if (!line.trim()) continue;
    const obj = JSON.parse(line);
    total++;
    if (obj.outcome === "engaged") positive++;
}

const baselineAUC = 0.5; // random baseline
console.log(`Loaded ${total} rows, positive=${positive}`);
console.log(`Baseline ROC-AUC=${baselineAUC}`);
