// routes/conversation.controller.ts
// Controller for conversation endpoint (default route).

import { processConversation } from '../services/conversation.service.ts'

interface ControllerOptions {
  cors: Record<string, string>
  isTestingEnv: boolean
}

export async function conversationController(
  req: Request,
  { cors, isTestingEnv }: ControllerOptions,
): Promise<Response> {
  return await processConversation(req, { cors, isTestingEnv })
}
