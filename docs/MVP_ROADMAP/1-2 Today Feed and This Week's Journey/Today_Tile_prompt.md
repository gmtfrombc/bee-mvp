Short answer  
• 1-2 tightly written sentences will work, but 3-6 sentences (≈ 40-80 tokens) gives the model far more signal for behaviour-specific topics.  
• Store a small “seed” blob (title + context) in a Supabase table, fetch it inside `daily-content-generator`, and mount it into the LLM prompt.  

Why 3-6 sentences?  
1. Hallucination risk falls sharply once the prompt contains the key concept, a why-it-matters angle, and 1-2 concrete examples.  
2. That size is still only ~5 % of a typical 4-par graph article, so you keep latency low and remain within the 8 K token window you’re already targeting.  
3. You can machine-validate a paragraph for policy / PHI red flags before it reaches the LLM.

Schema suggestion (`supabase.daily_content_topic_seeds`)  
• id uuid (PK)  
• slug text UNIQUE (e.g. “habit-stacking”)  
• title text  
• context text (≤ 600 chars) – the paragraph you author  
• min_days_between_uses int DEFAULT 14  
• last_used_at timestamptz  

Generator flow (edge function)  
1. Pick a seed that hasn’t run in `min_days_between_uses`.  
2. Prompt template:  

```
You are a behaviour-change health coach.  
Topic: {{title}}  
Background: {{context}}  
Write a 250-word article for the Today Feed. Use second-person, positive tone…
```  

3. Post-process, store final article in `daily_content` table, update `last_used_at`.  

Tips for authoring the context paragraph  
• First sentence – define the concept (“Habit stacking = linking a new habit to an existing cue”).  
• Second – why it matters for lifestyle change.  
• Third / fourth – one vivid example and a caveat or common mistake.  
• Avoid jargon you don’t want echoed back.  

If you really must keep it to 1-2 lines, include at least: definition + desired takeaway + example fragment. Otherwise expect generic output.

Where to store?  
Supabase works well because:  
• seed data lives with the rest of your content DB;  
• easy SQL filter in step 1;  
• edge function already has DB client.  
If you’d rather keep version control history, treat the table as runtime and source-of-truth YAML/CSV in `supabase/seed/` that you load via migration.

Bottom line  
Write a short paragraph per topic, store it in a dedicated `daily_content_topic_seeds` table, and feed that paragraph into the existing edge-function prompt. That yields specific, on-brand articles without blowing up tokens or refactoring the pipeline.