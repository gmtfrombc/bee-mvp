import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { afterEach, beforeEach, describe, it } from 'https://deno.land/std@0.168.0/testing/bdd.ts'
import { buildPrompt } from './prompt-builder.ts'
import type { PatternSummary } from './personalization/pattern-analysis.ts'
import type { ConversationLog } from './response-logger.ts'

// Mock Deno.readTextFile for template loading
const originalReadTextFile = Deno.readTextFile

describe('Prompt Builder', () => {
    beforeEach(() => {
        // Mock template file loading
        Deno.readTextFile = async (path: string): Promise<string> => {
            if (path.includes('safety.md')) {
                return '# Safety Guidelines\nYou are a responsible AI coach...'
            }
            if (path.includes('system.md')) {
                return `# System Prompt
Momentum State: {{momentum_state}}
Persona: {{persona}}
Engagement: {{engagement_summary}}`
            }
            throw new Error(`Template not found: ${path}`)
        }
    })

    afterEach(() => {
        Deno.readTextFile = originalReadTextFile
    })

    it('should inject persona tokens correctly', async () => {
        const mockSummary: PatternSummary = {
            engagementPeaks: ['morning', 'evening'],
            volatilityScore: 0.3
        }

        const prompt = await buildPrompt(
            'I need help with my goals',
            'supportive',
            mockSummary,
            'NeedsCare'
        )

        // Should have system message with injected context
        const systemMessage = prompt.find(msg => msg.role === 'system')
        assertExists(systemMessage)

        // Check that template variables were replaced
        assertEquals(systemMessage.content.includes('{{momentum_state}}'), false)
        assertEquals(systemMessage.content.includes('{{persona}}'), false)
        assertEquals(systemMessage.content.includes('{{engagement_summary}}'), false)

        // Check that actual values were injected
        assertEquals(systemMessage.content.includes('NeedsCare'), true)
        assertEquals(systemMessage.content.includes('supportive'), true)
        assertEquals(systemMessage.content.includes('morning, evening'), true)
    })

    it('should include conversation history correctly', async () => {
        const mockSummary: PatternSummary = {
            engagementPeaks: [],
            volatilityScore: 0.5
        }

        const conversationHistory: ConversationLog[] = [
            {
                user_id: 'test-user',
                role: 'user',
                content: 'Hello coach',
                timestamp: '2025-01-01T10:00:00Z'
            },
            {
                user_id: 'test-user',
                role: 'assistant',
                content: 'Hello! How can I help you today?',
                persona: 'supportive',
                timestamp: '2025-01-01T10:00:30Z'
            }
        ]

        const prompt = await buildPrompt(
            'I need more help',
            'educational',
            mockSummary,
            'Steady',
            conversationHistory
        )

        // Should have system, previous user, previous assistant, and current user messages
        assertEquals(prompt.length, 4)
        assertEquals(prompt[0].role, 'system')
        assertEquals(prompt[1].role, 'user')
        assertEquals(prompt[1].content, 'Hello coach')
        assertEquals(prompt[2].role, 'assistant')
        assertEquals(prompt[2].content, 'Hello! How can I help you today?')
        assertEquals(prompt[3].role, 'user')
        assertEquals(prompt[3].content, 'I need more help')
    })

    it('should filter out system messages from conversation history', async () => {
        const mockSummary: PatternSummary = {
            engagementPeaks: ['afternoon'],
            volatilityScore: 0.2
        }

        const conversationHistory: ConversationLog[] = [
            {
                user_id: 'test-user',
                role: 'system',
                content: 'System message should be filtered',
                timestamp: '2025-01-01T09:00:00Z'
            },
            {
                user_id: 'test-user',
                role: 'user',
                content: 'User message should remain',
                timestamp: '2025-01-01T10:00:00Z'
            }
        ]

        const prompt = await buildPrompt(
            'Current message',
            'challenging',
            mockSummary,
            'Rising',
            conversationHistory
        )

        // Should have system (from template), user (from history), and current user message
        assertEquals(prompt.length, 3)
        assertEquals(prompt[0].role, 'system')
        assertEquals(prompt[1].role, 'user')
        assertEquals(prompt[1].content, 'User message should remain')
        assertEquals(prompt[2].role, 'user')
        assertEquals(prompt[2].content, 'Current message')
    })

    it('should format engagement summary with no peaks', async () => {
        const mockSummary: PatternSummary = {
            engagementPeaks: [],
            volatilityScore: 0.8
        }

        const prompt = await buildPrompt(
            'Test message',
            'supportive',
            mockSummary,
            'Steady'
        )

        const systemMessage = prompt.find(msg => msg.role === 'system')
        assertExists(systemMessage)

        // Should include "No clear engagement patterns" message
        assertEquals(systemMessage.content.includes('No clear engagement patterns'), true)
        assertEquals(systemMessage.content.includes('80%'), true) // Volatility percentage
    })

    it('should format engagement summary with multiple peaks', async () => {
        const mockSummary: PatternSummary = {
            engagementPeaks: ['morning', 'afternoon', 'evening'],
            volatilityScore: 0.6
        }

        const prompt = await buildPrompt(
            'Test message',
            'educational',
            mockSummary,
            'Rising'
        )

        const systemMessage = prompt.find(msg => msg.role === 'system')
        assertExists(systemMessage)

        // Should include formatted peaks and volatility level
        assertEquals(systemMessage.content.includes('morning, afternoon, evening'), true)
        assertEquals(systemMessage.content.includes('Moderate'), true) // Volatility level
        assertEquals(systemMessage.content.includes('60%'), true) // Volatility percentage
    })
}) 