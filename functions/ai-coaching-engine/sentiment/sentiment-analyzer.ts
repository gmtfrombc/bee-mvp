export interface SentimentResult {
    score: number; // -1 to 1 range
    label: 'negative' | 'neutral' | 'positive';
}

/**
 * Analyzes sentiment of user text using rule-based approach or remote model
 * Returns sentiment score (-1 to 1) and categorical label
 */
export async function analyzeSentiment(text: string): Promise<SentimentResult> {
    const sentimentModel = Deno.env.get('SENTIMENT_MODEL') || 'local';

    if (sentimentModel === 'remote') {
        return await analyzeRemoteSentiment(text);
    }

    return analyzeLocalSentiment(text);
}

/**
 * Rule-based local sentiment analysis
 * Fast and deterministic - good for real-time coaching responses
 */
function analyzeLocalSentiment(text: string): SentimentResult {
    const normalizedText = text.toLowerCase().trim();

    // Positive indicators
    const positiveWords = [
        'great', 'amazing', 'awesome', 'fantastic', 'wonderful', 'excellent',
        'love', 'happy', 'excited', 'thrilled', 'motivated', 'confident',
        'success', 'achieve', 'accomplished', 'proud', 'grateful', 'thankful',
        'hope', 'optimistic', 'better', 'improving', 'progress'
    ];

    // Negative indicators
    const negativeWords = [
        'terrible', 'awful', 'horrible', 'hate', 'frustrated', 'angry',
        'sad', 'depressed', 'worried', 'anxious', 'stressed', 'overwhelmed',
        'fail', 'failure', 'struggling', 'difficult', 'impossible', 'hopeless',
        'tired', 'exhausted', 'giving up', 'quit', 'can\'t', 'won\'t'
    ];

    // Intensifiers and negations
    const intensifiers = ['very', 'really', 'extremely', 'absolutely', 'totally'];
    const negations = ['not', 'no', 'never', 'don\'t', 'can\'t', 'won\'t', 'isn\'t'];

    let score = 0;
    const words = normalizedText.split(/\s+/);

    for (let i = 0; i < words.length; i++) {
        const word = words[i];
        const prevWord = i > 0 ? words[i - 1] : '';

        // Check for negation
        const isNegated = negations.includes(prevWord);

        // Check for intensifier
        const isIntensified = intensifiers.includes(prevWord);
        const multiplier = isIntensified ? 1.5 : 1.0;

        if (positiveWords.includes(word)) {
            score += isNegated ? -0.3 * multiplier : 0.3 * multiplier;
        } else if (negativeWords.includes(word)) {
            score += isNegated ? 0.3 * multiplier : -0.3 * multiplier;
        }
    }

    // Punctuation analysis
    const exclamationCount = (text.match(/!/g) || []).length;
    const questionCount = (text.match(/\?/g) || []).length;

    // Multiple exclamations suggest strong emotion
    if (exclamationCount > 1) {
        score = score > 0 ? score + 0.2 : score - 0.2;
    }

    // Excessive questions might indicate confusion/frustration
    if (questionCount > 2) {
        score -= 0.1;
    }

    // Normalize score to -1 to 1 range
    score = Math.max(-1, Math.min(1, score));

    // Determine label
    let label: 'negative' | 'neutral' | 'positive';
    if (score >= 0.2) {
        label = 'positive';
    } else if (score <= -0.2) {
        label = 'negative';
    } else {
        label = 'neutral';
    }

    return { score, label };
}

/**
 * Remote sentiment analysis using Claude API
 * More nuanced but slower - use when SENTIMENT_MODEL=remote
 */
async function analyzeRemoteSentiment(text: string): Promise<SentimentResult> {
    const apiKey = Deno.env.get('AI_API_KEY');
    if (!apiKey) {
        console.warn('AI_API_KEY not available, falling back to local sentiment analysis');
        return analyzeLocalSentiment(text);
    }

    try {
        const response = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`,
                'anthropic-version': '2023-06-01'
            },
            body: JSON.stringify({
                model: 'claude-3-haiku-20240307',
                max_tokens: 50,
                messages: [{
                    role: 'user',
                    content: `Analyze the sentiment of this text and respond with ONLY a JSON object containing "score" (-1 to 1) and "label" (negative/neutral/positive): "${text}"`
                }]
            })
        });

        if (!response.ok) {
            throw new Error(`API request failed: ${response.status}`);
        }

        const data = await response.json();
        const content = data.content[0].text;

        // Parse JSON response
        const sentimentData = JSON.parse(content);

        return {
            score: Math.max(-1, Math.min(1, sentimentData.score)),
            label: sentimentData.label
        };
    } catch (error) {
        console.warn('Remote sentiment analysis failed, falling back to local:', error);
        return analyzeLocalSentiment(text);
    }
} 