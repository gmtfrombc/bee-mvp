// dynamic supabase client import helper
import { getSupabaseClient as _getSupabaseClient } from './_shared/supabase_client.ts'

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
  authToken?: string,
): Promise<string | null> {
  // Skip logging in test environment
  const isTestingEnvironment = Deno.env.get('DENO_TESTING') === 'true'
  if (isTestingEnvironment) {
    console.log(`🧪 Test environment: skipping conversation logging for user ${userId}`)
    return null
  }

  // Check for development mode (test user)
  const isTestUser = userId === '00000000-0000-0000-0000-000000000001'
  const isDevelopmentMode = supabaseUrl.includes('kong:8000') ||
    supabaseUrl.includes('127.0.0.1') || supabaseUrl.includes('localhost')

  // Use service role key in development mode to bypass RLS
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SERVICE_ROLE_KEY')
  const keyToUse = (isDevelopmentMode && isTestUser && serviceRoleKey)
    ? serviceRoleKey
    : supabaseKey

  if (isDevelopmentMode && isTestUser) {
    console.log(`🧪 Development mode logging - Service role key available: ${!!serviceRoleKey}`)
    console.log(`🧪 Using key type: ${serviceRoleKey ? 'service_role' : 'anon'}`)
  }

  const { createClient } = await import('npm:@supabase/supabase-js@2')
  const supabase = createClient(supabaseUrl, keyToUse, {
    global: {
      headers: authToken ? { Authorization: `Bearer ${authToken}` } : {},
    },
  })

  const logEntry: ConversationLog = {
    user_id: userId,
    role,
    content,
    persona,
    timestamp: new Date().toISOString(),
  }

  const { data, error } = await supabase
    .from('conversation_logs')
    .insert(logEntry)
    .select('id')
    .single()

  if (error) {
    console.error('Failed to log conversation:', error)

    // In development mode with test user, don't fail the entire request for logging issues
    if (isDevelopmentMode && isTestUser && error.code === '42501') {
      console.log(
        '🧪 Development mode: Skipping conversation logging due to RLS policy - continuing without database log',
      )
      return null // Return null but don't throw error
    }

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
  authToken?: string,
): Promise<ConversationLog[]> {
  // Skip fetching messages in test environment
  const isTestingEnvironment = Deno.env.get('DENO_TESTING') === 'true'
  if (isTestingEnvironment) {
    console.log(`🧪 Test environment: returning empty conversation history for user ${userId}`)
    return []
  }

  // Check for development mode (test user)
  const isTestUser = userId === '00000000-0000-0000-0000-000000000001'
  const isDevelopmentMode = supabaseUrl.includes('kong:8000') ||
    supabaseUrl.includes('127.0.0.1') || supabaseUrl.includes('localhost')

  // Use service role key in development mode to bypass RLS
  const keyToUse = (isDevelopmentMode && isTestUser)
    ? (Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || supabaseKey)
    : supabaseKey

  const { createClient } = await import('npm:@supabase/supabase-js@2')
  const supabase = createClient(supabaseUrl, keyToUse, {
    global: {
      headers: authToken ? { Authorization: `Bearer ${authToken}` } : {},
    },
  })

  const { data, error } = await supabase
    .from('conversation_logs')
    .select('*')
    .eq('user_id', userId)
    .order('timestamp', { ascending: false })
    .limit(limit)

  if (error) {
    console.error('Failed to fetch recent messages:', error)

    // In development mode with test user, return empty array instead of failing
    if (isDevelopmentMode && isTestUser && error.code === '42501') {
      console.log(
        '🧪 Development mode: No conversation history available due to RLS policy - returning empty array',
      )
      return []
    }

    throw new Error(`Failed to fetch recent messages: ${error.message}`)
  }

  // Return in chronological order (oldest first) for conversation context
  return (data || []).reverse()
}
