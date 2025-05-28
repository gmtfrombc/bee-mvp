/// <reference path="./types.d.ts" />

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Types for real-time momentum sync
interface RealtimeSubscriptionRequest {
    user_id: string
    channels: string[]
    client_id: string
    platform: 'ios' | 'android' | 'web'
    app_version?: string
}

interface MomentumSyncResponse {
    success: boolean
    data?: any
    error?: string
    timestamp: string
    client_id: string
}

interface CacheInvalidationEvent {
    cache_key: string
    user_id: string
    timestamp: string
}

interface RealtimeEvent {
    event_type: string
    user_id: string
    payload: Record<string, any>
    timestamp: string
}

class RealtimeMomentumSync {
    private supabase: any
    private connectedClients: Map<string, WebSocket> = new Map()
    private userSubscriptions: Map<string, Set<string>> = new Map()

    constructor(supabaseUrl: string, supabaseKey: string) {
        this.supabase = createClient(supabaseUrl, supabaseKey)
    }

    /**
     * Handle WebSocket connection for real-time momentum updates
     */
    async handleWebSocketConnection(request: Request): Promise<Response> {
        const { socket, response } = Deno.upgradeWebSocket(request)
        const url = new URL(request.url)
        const userId = url.searchParams.get('user_id')
        const clientId = url.searchParams.get('client_id') || crypto.randomUUID()

        if (!userId) {
            socket.close(1008, 'Missing user_id parameter')
            return response
        }

        socket.onopen = () => {
            console.log(`WebSocket connected for user ${userId}, client ${clientId}`)
            this.connectedClients.set(clientId, socket)

            // Subscribe user to their momentum channels
            this.subscribeUserToChannels(userId, clientId)

            // Send initial momentum state
            this.sendInitialMomentumState(userId, clientId)
        }

        socket.onmessage = (event) => {
            try {
                const message = JSON.parse(event.data)
                this.handleClientMessage(message, userId, clientId)
            } catch (error) {
                console.error('Error parsing WebSocket message:', error)
                this.sendError(clientId, 'Invalid message format')
            }
        }

        socket.onclose = () => {
            console.log(`WebSocket disconnected for user ${userId}, client ${clientId}`)
            this.connectedClients.delete(clientId)
            this.cleanupUserSubscriptions(userId, clientId)
        }

        socket.onerror = (error) => {
            console.error(`WebSocket error for user ${userId}:`, error)
            this.connectedClients.delete(clientId)
        }

        return response
    }

    /**
     * Subscribe user to their momentum-related channels
     */
    private async subscribeUserToChannels(userId: string, clientId: string) {
        const channels = [
            `momentum_updates:${userId}`,
            `interventions:${userId}`,
            `notifications:${userId}`,
            'cache_invalidation'
        ]

        // Store user subscriptions
        if (!this.userSubscriptions.has(userId)) {
            this.userSubscriptions.set(userId, new Set())
        }
        this.userSubscriptions.get(userId)!.add(clientId)

        // Set up Supabase realtime subscriptions
        for (const channel of channels) {
            this.supabase
                .channel(channel)
                .on('postgres_changes', { event: '*', schema: 'public' }, (payload: any) => {
                    this.handleRealtimeEvent(payload, userId, clientId)
                })
                .subscribe()
        }

        // Confirm subscription
        this.sendMessage(clientId, {
            type: 'subscription_confirmed',
            channels,
            user_id: userId,
            timestamp: new Date().toISOString()
        })
    }

    /**
     * Send initial momentum state to newly connected client
     */
    private async sendInitialMomentumState(userId: string, clientId: string) {
        try {
            // Get current momentum state
            const { data: momentumState, error: momentumError } = await this.supabase
                .rpc('get_realtime_momentum_state', { target_user_id: userId })

            if (momentumError) {
                throw momentumError
            }

            // Get pending interventions
            const { data: interventions, error: interventionsError } = await this.supabase
                .rpc('get_realtime_interventions', { target_user_id: userId })

            if (interventionsError) {
                throw interventionsError
            }

            // Send initial state
            this.sendMessage(clientId, {
                type: 'initial_state',
                momentum: momentumState,
                interventions,
                timestamp: new Date().toISOString()
            })

        } catch (error) {
            console.error('Error sending initial momentum state:', error)
            this.sendError(clientId, 'Failed to load initial momentum state')
        }
    }

    /**
     * Handle incoming messages from clients
     */
    private async handleClientMessage(message: any, userId: string, clientId: string) {
        switch (message.type) {
            case 'ping':
                this.sendMessage(clientId, {
                    type: 'pong',
                    timestamp: new Date().toISOString()
                })
                break

            case 'request_momentum_update':
                await this.sendCurrentMomentumState(userId, clientId)
                break

            case 'mark_notification_read':
                await this.markNotificationRead(message.notification_id, userId, clientId)
                break

            case 'cache_invalidation_ack':
                await this.handleCacheInvalidationAck(message.cache_key, userId, clientId)
                break

            default:
                this.sendError(clientId, `Unknown message type: ${message.type}`)
        }
    }

    /**
     * Handle real-time events from Supabase
     */
    private handleRealtimeEvent(payload: any, userId: string, clientId: string) {
        const event: RealtimeEvent = {
            event_type: payload.eventType,
            user_id: userId,
            payload: payload.new || payload.old,
            timestamp: new Date().toISOString()
        }

        // Filter events for this user
        if (payload.new?.user_id === userId || payload.old?.user_id === userId) {
            this.sendMessage(clientId, {
                type: 'realtime_event',
                event,
                timestamp: new Date().toISOString()
            })

            // Log event metrics
            this.logRealtimeEvent(event.event_type, `realtime:${userId}`, userId)
        }
    }

    /**
     * Send current momentum state to client
     */
    private async sendCurrentMomentumState(userId: string, clientId: string) {
        try {
            const { data, error } = await this.supabase
                .rpc('get_realtime_momentum_state', { target_user_id: userId })

            if (error) {
                throw error
            }

            this.sendMessage(clientId, {
                type: 'momentum_state_update',
                data,
                timestamp: new Date().toISOString()
            })

        } catch (error) {
            console.error('Error getting momentum state:', error)
            this.sendError(clientId, 'Failed to get momentum state')
        }
    }

    /**
     * Mark notification as read
     */
    private async markNotificationRead(notificationId: string, userId: string, clientId: string) {
        try {
            const { error } = await this.supabase
                .from('momentum_notifications')
                .update({
                    status: 'opened',
                    opened_at: new Date().toISOString()
                })
                .eq('id', notificationId)
                .eq('user_id', userId)

            if (error) {
                throw error
            }

            this.sendMessage(clientId, {
                type: 'notification_marked_read',
                notification_id: notificationId,
                timestamp: new Date().toISOString()
            })

        } catch (error) {
            console.error('Error marking notification as read:', error)
            this.sendError(clientId, 'Failed to mark notification as read')
        }
    }

    /**
     * Handle cache invalidation acknowledgment
     */
    private async handleCacheInvalidationAck(cacheKey: string, userId: string, clientId: string) {
        // Log cache invalidation metrics
        await this.logRealtimeEvent('cache_invalidation_ack', cacheKey, userId)

        this.sendMessage(clientId, {
            type: 'cache_invalidation_confirmed',
            cache_key: cacheKey,
            timestamp: new Date().toISOString()
        })
    }

    /**
     * Send message to specific client
     */
    private sendMessage(clientId: string, message: any) {
        const socket = this.connectedClients.get(clientId)
        if (socket && socket.readyState === WebSocket.OPEN) {
            try {
                socket.send(JSON.stringify(message))
            } catch (error) {
                console.error(`Error sending message to client ${clientId}:`, error)
                this.connectedClients.delete(clientId)
            }
        }
    }

    /**
     * Send error message to client
     */
    private sendError(clientId: string, errorMessage: string) {
        this.sendMessage(clientId, {
            type: 'error',
            error: errorMessage,
            timestamp: new Date().toISOString()
        })
    }

    /**
     * Clean up user subscriptions when client disconnects
     */
    private cleanupUserSubscriptions(userId: string, clientId: string) {
        const userClients = this.userSubscriptions.get(userId)
        if (userClients) {
            userClients.delete(clientId)
            if (userClients.size === 0) {
                this.userSubscriptions.delete(userId)
            }
        }
    }

    /**
     * Log real-time event metrics
     */
    private async logRealtimeEvent(eventType: string, channelName: string, userId: string) {
        try {
            await this.supabase.rpc('log_realtime_event', {
                p_event_type: eventType,
                p_channel_name: channelName,
                p_user_id: userId,
                p_processing_time_ms: null,
                p_success: true
            })
        } catch (error) {
            console.error('Error logging realtime event:', error)
        }
    }

    /**
     * Handle HTTP requests for momentum sync
     */
    async handleHttpRequest(request: Request): Promise<Response> {
        const url = new URL(request.url)
        const path = url.pathname

        try {
            switch (path) {
                case '/sync/momentum':
                    return await this.handleMomentumSync(request)

                case '/sync/interventions':
                    return await this.handleInterventionsSync(request)

                case '/sync/notifications':
                    return await this.handleNotificationsSync(request)

                case '/sync/health':
                    return this.handleHealthCheck()

                default:
                    return new Response(
                        JSON.stringify({ error: 'Not found' }),
                        { status: 404, headers: { 'Content-Type': 'application/json' } }
                    )
            }
        } catch (error) {
            console.error('Error handling HTTP request:', error)
            return new Response(
                JSON.stringify({
                    error: 'Internal server error',
                    message: error.message
                }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
        }
    }

    /**
     * Handle momentum sync request
     */
    private async handleMomentumSync(request: Request): Promise<Response> {
        const { user_id } = await request.json()

        if (!user_id) {
            return new Response(
                JSON.stringify({ error: 'Missing user_id' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        const { data, error } = await this.supabase
            .rpc('get_realtime_momentum_state', { target_user_id: user_id })

        if (error) {
            return new Response(
                JSON.stringify({ error: error.message }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify({
                success: true,
                data,
                timestamp: new Date().toISOString()
            }),
            { headers: { 'Content-Type': 'application/json' } }
        )
    }

    /**
     * Handle interventions sync request
     */
    private async handleInterventionsSync(request: Request): Promise<Response> {
        const { user_id } = await request.json()

        if (!user_id) {
            return new Response(
                JSON.stringify({ error: 'Missing user_id' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        const { data, error } = await this.supabase
            .rpc('get_realtime_interventions', { target_user_id: user_id })

        if (error) {
            return new Response(
                JSON.stringify({ error: error.message }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify({
                success: true,
                data,
                timestamp: new Date().toISOString()
            }),
            { headers: { 'Content-Type': 'application/json' } }
        )
    }

    /**
     * Handle notifications sync request
     */
    private async handleNotificationsSync(request: Request): Promise<Response> {
        const { user_id, limit = 50 } = await request.json()

        if (!user_id) {
            return new Response(
                JSON.stringify({ error: 'Missing user_id' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        const { data, error } = await this.supabase
            .from('momentum_notifications')
            .select('*')
            .eq('user_id', user_id)
            .order('created_at', { ascending: false })
            .limit(limit)

        if (error) {
            return new Response(
                JSON.stringify({ error: error.message }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify({
                success: true,
                data,
                timestamp: new Date().toISOString()
            }),
            { headers: { 'Content-Type': 'application/json' } }
        )
    }

    /**
     * Handle health check
     */
    private handleHealthCheck(): Response {
        return new Response(
            JSON.stringify({
                status: 'healthy',
                connected_clients: this.connectedClients.size,
                active_subscriptions: this.userSubscriptions.size,
                timestamp: new Date().toISOString()
            }),
            { headers: { 'Content-Type': 'application/json' } }
        )
    }
}

// Main handler
serve(async (request: Request) => {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const syncHandler = new RealtimeMomentumSync(supabaseUrl, supabaseKey)

    // Handle WebSocket upgrade requests
    if (request.headers.get('upgrade') === 'websocket') {
        return await syncHandler.handleWebSocketConnection(request)
    }

    // Handle HTTP requests
    return await syncHandler.handleHttpRequest(request)
}) 