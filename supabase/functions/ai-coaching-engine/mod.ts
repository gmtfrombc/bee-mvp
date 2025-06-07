// AI Coaching Engine with Real OpenAI Integration

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
    // CORS pre-flight
    if (req.method === 'OPTIONS') {
        return new Response(null, { headers: corsHeaders });
    }

    if (req.method !== 'POST') {
        return new Response('Method not allowed', {
            status: 405,
            headers: corsHeaders
        });
    }

    const startTime = Date.now();

    try {
        const body = await req.json();
        const { user_id, message, momentum_state = 'Steady' } = body;

        console.log(`📨 User ${user_id}: "${message}" (momentum: ${momentum_state})`);

        if (!user_id || !message) {
            return new Response(JSON.stringify({
                error: 'Missing user_id or message'
            }), {
                status: 400,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
            });
        }

        // Get OpenAI API key from environment
        const openaiApiKey = Deno.env.get('OPENAI_API_KEY') || Deno.env.get('AI_API_KEY');

        if (!openaiApiKey) {
            throw new Error('OpenAI API key not configured');
        }

        // Build coaching prompt based on momentum state
        const systemPrompt = `You are a supportive health and wellness coach. The user's current momentum state is "${momentum_state}". 

Guidelines:
- Provide personalized, actionable advice
- Be encouraging and supportive
- Keep responses concise (2-3 sentences max)
- Focus on small, achievable steps
- If user asks for recipes, provide them
- If user asks about habits, give specific habit suggestions
- Adapt your tone to their momentum state:
  * Rising: Be encouraging and challenging
  * Steady: Be supportive and educational  
  * Needs Care: Be extra gentle and caring`;

        // Make OpenAI API call
        console.log('🤖 Calling OpenAI API...');

        const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${openaiApiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model: 'gpt-4',
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: message }
                ],
                max_tokens: 150,
                temperature: 0.7,
            }),
        });

        if (!openaiResponse.ok) {
            const error = await openaiResponse.text();
            console.error('❌ OpenAI API error:', error);
            throw new Error(`OpenAI API failed: ${openaiResponse.status}`);
        }

        const openaiData = await openaiResponse.json();
        const aiMessage = openaiData.choices[0]?.message?.content || 'I apologize, I\'m having trouble generating a response right now.';

        console.log(`✅ OpenAI response: "${aiMessage}"`);

        // Return in format expected by Flutter app
        const response = {
            assistant_message: aiMessage,
            persona: momentum_state === 'Rising' ? 'challenging' :
                momentum_state === 'Needs Care' ? 'caring' : 'supportive',
            response_time_ms: Date.now() - startTime,
            cache_hit: false
        };

        return new Response(JSON.stringify(response), {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

    } catch (error) {
        console.error('❌ Function error:', error);

        // Return error response
        return new Response(JSON.stringify({
            error: 'AI coaching service error',
            message: error.message || 'Unknown error'
        }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
});

// NOTE: No export needed – Deno.serve starts the HTTP handler automatically 