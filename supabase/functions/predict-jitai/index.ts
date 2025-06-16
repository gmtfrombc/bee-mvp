import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { evaluateJITAITriggers } from "../ai-coaching-engine/services/jitai-engine.ts";
import { JITAITrigger, WearableData } from "../ai-coaching-engine/types.ts";

// ------------------------------
// MODEL LOADING & SCORING
// ------------------------------

interface LogisticModel {
    intercept: number;
    coeff: Record<string, number>;
    /** Optional probability threshold to qualify a trigger */
    threshold?: number;
}

let logisticModel: LogisticModel | null = null;
async function loadModel(): Promise<void> {
    if (logisticModel) return;
    const url = Deno.env.get("JITAI_MODEL_URL");
    if (!url) return;
    try {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        logisticModel = await res.json();
        console.log(
            `[predict-jitai] Logistic model loaded – features: ${
                Object.keys((logisticModel as LogisticModel).coeff).join(",")
            }`,
        );
    } catch (err) {
        console.error("[predict-jitai] model load failed", err);
    }
}

await loadModel();

function probability(
    snapshot: WearableData,
    sleep_score?: number,
    avg_hr?: number,
): number {
    const model = logisticModel;
    if (!model) return 0;
    const { intercept, coeff } = model;
    let z = intercept;
    const add = (name: string, value: number | undefined) => {
        if (value === undefined) return;
        const w = coeff[name];
        if (w !== undefined) z += w * value;
    };
    add("sleep_score", sleep_score);
    add("avg_hr", avg_hr);
    add("steps", snapshot.steps);
    add("heart_rate", snapshot.heart_rate);
    add("resting_heart_rate", snapshot.resting_heart_rate);
    add("stress_level", snapshot.stress_level);
    // logistic function
    return 1 / (1 + Math.exp(-z));
}

interface PredictRequest {
    user_id: string;
    wearable_snapshot: WearableData;
    sleep_score?: number;
    avg_hr?: number;
}

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST") return json({ error: "POST required" }, 405);

    try {
        const body: PredictRequest = await req.json();
        const { user_id, wearable_snapshot, sleep_score, avg_hr } = body;

        if (!user_id || !wearable_snapshot) {
            return json(
                { error: "user_id and wearable_snapshot required" },
                400,
            );
        }

        let triggers: JITAITrigger[] = evaluateJITAITriggers(
            user_id,
            wearable_snapshot,
        );

        // If model loaded, score & rank triggers
        if (logisticModel) {
            const withScores = triggers.map((t) => ({
                trigger: t,
                score: probability(wearable_snapshot, sleep_score, avg_hr),
            }));

            // Filter by threshold if provided
            const threshold = logisticModel.threshold ?? 0.5;
            triggers = withScores
                .filter((t) => t.score >= threshold)
                .sort((a, b) => b.score - a.score)
                .map((
                    t,
                ) => ({ ...t.trigger, probability: t.score } as JITAITrigger & {
                    probability: number;
                }));

            return json({ triggers, source: "model" });
        }

        // Fallback to rule engine (unsorted)
        return json({ triggers, source: "rules" });
    } catch (err) {
        console.error("predict-jitai error", err);
        return json({ error: "internal" }, 500);
    }
});

function json(payload: unknown, status = 200): Response {
    return new Response(JSON.stringify(payload), {
        status,
        headers: { "Content-Type": "application/json" },
    });
}
