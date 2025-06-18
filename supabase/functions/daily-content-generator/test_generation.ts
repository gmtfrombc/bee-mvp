#!/usr/bin/env deno run --allow-all

/**
 * Test script for daily content generation
 * Tests M1.2.1.1 AI Content Generation Infrastructure
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
    "dummy-key";

async function testContentGeneration() {
    console.log("🧪 Testing M1.2.1.1 AI Content Generation Infrastructure");
    console.log("=".repeat(60));

    try {
        // Test 1: Check if daily-content-generator function exists
        console.log("\n📋 Test 1: Testing daily-content-generator function");
        const testDate = new Date().toISOString().split("T")[0];

        const response = await fetch(
            `${supabaseUrl}/functions/v1/daily-content-generator`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${supabaseServiceKey}`,
                },
                body: JSON.stringify({
                    target_date: testDate,
                    force_regenerate: true,
                }),
            },
        );

        if (response.ok) {
            const result = await response.json();
            console.log("✅ Daily content generator function is working");
            console.log(`📝 Response: ${JSON.stringify(result, null, 2)}`);
        } else {
            console.log(
                `❌ Daily content generator failed: ${response.status} - ${await response
                    .text()}`,
            );
        }

        // Test 2: Check if database schema exists
        console.log("\n📋 Test 2: Testing database schema");
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        const { data: _contentCheck, error: contentError } = await supabase
            .from("daily_feed_content")
            .select("count(*)")
            .limit(1);

        if (!contentError) {
            console.log("✅ daily_feed_content table exists");
        } else {
            console.log(
                `❌ daily_feed_content table error: ${contentError.message}`,
            );
        }

        const { data: _jobsCheck, error: jobsError } = await supabase
            .from("content_generation_jobs")
            .select("count(*)")
            .limit(1);

        if (!jobsError) {
            console.log("✅ content_generation_jobs table exists");
        } else {
            console.log(
                `❌ content_generation_jobs table error: ${jobsError.message}`,
            );
        }

        // Test 3: Check if AI coaching engine is accessible
        console.log("\n📋 Test 3: Testing AI coaching engine");
        const aiResponse = await fetch(
            `${supabaseUrl}/functions/v1/ai-coaching-engine/generate-daily-content`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Bearer ${supabaseServiceKey}`,
                },
                body: JSON.stringify({
                    content_date: testDate,
                    force_regenerate: true,
                }),
            },
        );

        if (aiResponse.ok) {
            const aiResult = await aiResponse.json();
            console.log("✅ AI coaching engine is accessible");
            console.log(`🧠 AI Response success: ${aiResult.success}`);
        } else {
            console.log(
                `❌ AI coaching engine failed: ${aiResponse.status} - ${await aiResponse
                    .text()}`,
            );
        }

        // Test 4: Test scheduled job function
        console.log("\n📋 Test 4: Testing scheduled job function");
        try {
            const { data: functionResult, error: functionError } =
                await supabase
                    .rpc("trigger_daily_content_generation", {
                        p_target_date: testDate,
                        p_force_regenerate: true,
                        p_triggered_by: "manual_test",
                    });

            if (!functionError) {
                console.log(
                    "✅ trigger_daily_content_generation function works",
                );
                console.log(`📊 Job ID: ${functionResult}`);
            } else {
                console.log(
                    `❌ trigger_daily_content_generation failed: ${functionError.message}`,
                );
            }
        } catch (e) {
            console.log(`❌ Function test error: ${e}`);
        }

        console.log(
            "\n🎯 M1.2.1.1 AI Content Generation Infrastructure Test Complete!",
        );
        console.log("=".repeat(60));
    } catch (error) {
        console.error("❌ Test failed:", error);
    }
}

// Run the test
if (import.meta.main) {
    await testContentGeneration();
}
