export type RedFlag = 'self_harm' | 'violence' | 'emergency' | 'phi_request';

interface RedFlagPattern {
    category: RedFlag;
    patterns: RegExp[];
    keywords: string[];
}

const RED_FLAG_PATTERNS: RedFlagPattern[] = [
    {
        category: 'self_harm',
        patterns: [
            /\b(kill|hurt|harm|cut|suicide|die|death|end|life|over)\s*(my)?self\b/i,
            /\b(want|going|plan|thinking|thought).*(die|kill|suicide|end|hurt).*(myself|my life)\b/i,
            /\bno\s*(longer|more)\s*(want|care)\s*to\s*live\b/i,
            /\bthoughts?\s*of\s*(suicide|self.harm|dying|killing)\b/i,
        ],
        keywords: ['suicidal', 'self-harm', 'cutting', 'overdose', 'worthless life', 'better off dead']
    },
    {
        category: 'violence',
        patterns: [
            /\b(kill|hurt|harm|attack|violence).*(others?|someone|people|family|person)\b/i,
            /\b(going|want|plan).*(hurt|kill|attack|harm).*(people|others?|someone)\b/i,
            /\bthoughts?\s*of\s*(violence|hurting|killing|attacking)\b/i,
        ],
        keywords: ['violent thoughts', 'hurt others', 'attack people', 'kill someone']
    },
    {
        category: 'emergency',
        patterns: [
            /\b(call\s*911|911\s*emergency|medical\s*emergency|urgent\s*medical)\b/i,
            /\b(chest|heart)\s*(pain|attack|problem)\b/i,
            /\b(can'?t|cannot)\s*(breathe|breathing)\b/i,
            /\b(overdose|poisoning|bleeding\s*out|unconscious)\b/i,
        ],
        keywords: ['medical emergency', 'heart attack', 'can\'t breathe', 'overdosed', 'bleeding out', 'call 911']
    },
    {
        category: 'phi_request',
        patterns: [
            /\b(tell|show|give|share)\s*me\s*(my|other).*(ssn|social\s*security|medical\s*record|insurance)\b/i,
            /\b(what|show)\s*(is|are)\s*(my|other).*(ssn|social\s*security|address|phone)\b/i,
            /\b(access|show|tell)\s*me.*(personal|private|confidential).*(data|info|information)\b/i,
        ],
        keywords: ['social security number', 'medical records', 'my personal information', 'my private data', 'my insurance info']
    }
];

/**
 * Detects red flags in user input that require special handling
 * @param text - User input to analyze
 * @returns RedFlag category if detected, null if clean
 */
export function detectRedFlags(text: string): RedFlag | null {
    const normalizedText = text.toLowerCase().trim();

    for (const flagPattern of RED_FLAG_PATTERNS) {
        // Check regex patterns
        for (const pattern of flagPattern.patterns) {
            if (pattern.test(text)) {
                return flagPattern.category;
            }
        }

        // Check keywords
        for (const keyword of flagPattern.keywords) {
            if (normalizedText.includes(keyword.toLowerCase())) {
                return flagPattern.category;
            }
        }
    }

    return null;
} 