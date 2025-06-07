import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!

export type ConversationRole = 'user' | 'assistant' | 'system'

export interface ConversationLog {
    user_id: string
    role: ConversationRole
    content: string
    persona?: string
    timestamp?: string
}

/**
 * Logs a conversation entry to the conversation_logs table
 * RLS policies ensure users can only access their own conversation data
 * Returns the conversation log ID for linking to effectiveness tracking
 */
export async function logConversation(
    userId: string,
    role: ConversationRole,
    content: string,
    persona?: string,
    authToken?: string
): Promise<string | null> {
    const supabase = createClient(supabaseUrl, supabaseKey, {
        global: {
            headers: authToken ? { Authorization: `Bearer ${authToken}` } : {}
        }
    })

    const logEntry: ConversationLog = {
        user_id: userId,
        role,
        content,
        persona,
        timestamp: new Date().toISOString()
    }

    const { data, error } = await supabase
        .from('conversation_logs')
        .insert(logEntry)
        .select('id')
        .single()

    if (error) {
        console.error('Failed to log conversation:', error)
        throw new Error(`Failed to log conversation: ${error.message}`)
    }

    return data?.id || null
}

/**
 * Retrieves the last N conversation messages for a user
 * Used to maintain conversation context for the AI
 */
export async function getRecentMessages(
    userId: string,
    limit: number = 20,
    authToken?: string
): Promise<ConversationLog[]> {
    const supabase = createClient(supabaseUrl, supabaseKey, {
        global: {
            headers: authToken ? { Authorization: `Bearer ${authToken}` } : {}
        }
    })

    const { data, error } = await supabase
        .from('conversation_logs')
        .select('*')
        .eq('user_id', userId)
        .order('timestamp', { ascending: false })
        .limit(limit)

    if (error) {
        console.error('Failed to fetch recent messages:', error)
        throw new Error(`Failed to fetch recent messages: ${error.message}`)
    }

    // Return in chronological order (oldest first) for conversation context
    return (data || []).reverse()
} 