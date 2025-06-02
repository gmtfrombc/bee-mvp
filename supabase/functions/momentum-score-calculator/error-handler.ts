// Error Handler for Momentum Score Calculator
// Epic: 1.1 · Momentum Meter
// Task: T1.1.2.8 · Add data validation and error handling

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Error types and codes
export enum ErrorType {
    VALIDATION_ERROR = 'validation_error',
    CALCULATION_ERROR = 'calculation_error',
    API_ERROR = 'api_error',
    DATABASE_ERROR = 'database_error',
    SYSTEM_ERROR = 'system_error'
}

export enum ErrorSeverity {
    LOW = 'low',
    MEDIUM = 'medium',
    HIGH = 'high',
    CRITICAL = 'critical'
}

// Error interfaces
export interface MomentumError {
    type: ErrorType
    code: string
    message: string
    details?: Record<string, any>
    severity: ErrorSeverity
    userId?: string
    functionName?: string
    timestamp: string
}

export interface ValidationResult {
    isValid: boolean
    errors: string[]
    warnings?: string[]
}

export interface ErrorLogEntry {
    id?: string
    error_type: string
    error_code: string
    error_message: string
    error_details: Record<string, any>
    user_id?: string
    function_name?: string
    severity: string
    created_at?: string
}

export class MomentumErrorHandler {
    private supabase: any

    constructor(supabaseUrl: string, supabaseKey: string) {
        this.supabase = createClient(supabaseUrl, supabaseKey)
    }

    /**
     * Validate user ID format and existence
     */
    validateUserId(userId: string): ValidationResult {
        const errors: string[] = []

        if (!userId) {
            errors.push('User ID is required')
        } else if (typeof userId !== 'string') {
            errors.push('User ID must be a string')
        } else if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId)) {
            errors.push('User ID must be a valid UUID format')
        } else if (userId === '00000000-0000-0000-0000-000000000000') {
            errors.push('User ID cannot be empty UUID')
        }

        return {
            isValid: errors.length === 0,
            errors
        }
    }

    /**
     * Validate date parameters
     */
    validateDate(date: string | Date, fieldName: string = 'date'): ValidationResult {
        const errors: string[] = []

        if (!date) {
            errors.push(`${fieldName} is required`)
            return { isValid: false, errors }
        }

        let dateObj: Date
        try {
            dateObj = typeof date === 'string' ? new Date(date) : date
        } catch (error) {
            errors.push(`${fieldName} must be a valid date`)
            return { isValid: false, errors }
        }

        if (isNaN(dateObj.getTime())) {
            errors.push(`${fieldName} must be a valid date`)
        } else if (dateObj > new Date()) {
            errors.push(`${fieldName} cannot be in the future`)
        } else if (dateObj < new Date(Date.now() - 2 * 365 * 24 * 60 * 60 * 1000)) {
            errors.push(`${fieldName} cannot be more than 2 years ago`)
        }

        return {
            isValid: errors.length === 0,
            errors
        }
    }

    /**
     * Validate score values
     */
    validateScoreValues(scores: {
        rawScore?: number
        normalizedScore?: number
        finalScore?: number
    }): ValidationResult {
        const errors: string[] = []
        const warnings: string[] = []

        // Validate raw score
        if (scores.rawScore !== undefined) {
            if (typeof scores.rawScore !== 'number') {
                errors.push('Raw score must be a number')
            } else if (scores.rawScore < 0) {
                errors.push('Raw score cannot be negative')
            } else if (scores.rawScore > 1000) {
                errors.push('Raw score cannot exceed 1000')
            } else if (scores.rawScore > 500) {
                warnings.push('Raw score is unusually high')
            }
        }

        // Validate normalized score
        if (scores.normalizedScore !== undefined) {
            if (typeof scores.normalizedScore !== 'number') {
                errors.push('Normalized score must be a number')
            } else if (scores.normalizedScore < 0 || scores.normalizedScore > 100) {
                errors.push('Normalized score must be between 0 and 100')
            }
        }

        // Validate final score
        if (scores.finalScore !== undefined) {
            if (typeof scores.finalScore !== 'number') {
                errors.push('Final score must be a number')
            } else if (scores.finalScore < 0 || scores.finalScore > 100) {
                errors.push('Final score must be between 0 and 100')
            }
        }

        return {
            isValid: errors.length === 0,
            errors,
            warnings
        }
    }

    /**
     * Validate momentum state
     */
    validateMomentumState(state: string): ValidationResult {
        const errors: string[] = []
        const validStates = ['Rising', 'Steady', 'NeedsCare']

        if (!state) {
            errors.push('Momentum state is required')
        } else if (!validStates.includes(state)) {
            errors.push(`Momentum state must be one of: ${validStates.join(', ')}`)
        }

        return {
            isValid: errors.length === 0,
            errors
        }
    }

    /**
     * Validate engagement events data
     */
    validateEngagementEvents(events: any[]): ValidationResult {
        const errors: string[] = []
        const warnings: string[] = []

        if (!Array.isArray(events)) {
            errors.push('Events must be an array')
            return { isValid: false, errors }
        }

        if (events.length === 0) {
            warnings.push('No engagement events provided')
        } else if (events.length > 1000) {
            errors.push('Too many events (maximum 1000)')
        }

        // Validate individual events
        events.forEach((event, index) => {
            if (!event.event_type) {
                errors.push(`Event ${index}: event_type is required`)
            }
            if (!event.created_at) {
                errors.push(`Event ${index}: created_at is required`)
            }
            if (event.points !== undefined && (typeof event.points !== 'number' || event.points < 0)) {
                errors.push(`Event ${index}: points must be a non-negative number`)
            }
        })

        return {
            isValid: errors.length === 0,
            errors,
            warnings
        }
    }

    /**
     * Log error to database
     */
    async logError(error: MomentumError): Promise<string | null> {
        try {
            const errorLog: ErrorLogEntry = {
                error_type: error.type,
                error_code: error.code,
                error_message: error.message,
                error_details: error.details || {},
                user_id: error.userId,
                function_name: error.functionName,
                severity: error.severity
            }

            const { data, error: dbError } = await this.supabase
                .from('momentum_error_logs')
                .insert(errorLog)
                .select('id')
                .single()

            if (dbError) {
                console.error('Failed to log error to database:', dbError)
                return null
            }

            return data?.id || null
        } catch (err) {
            console.error('Error logging to database:', err)
            return null
        }
    }

    /**
     * Create standardized error response
     */
    createErrorResponse(
        error: MomentumError,
        statusCode: number = 400
    ): Response {
        const responseBody = {
            success: false,
            error: {
                type: error.type,
                code: error.code,
                message: error.message,
                details: error.details,
                timestamp: error.timestamp
            }
        }

        return new Response(
            JSON.stringify(responseBody),
            {
                status: statusCode,
                headers: {
                    'Content-Type': 'application/json',
                    'X-Error-Type': error.type,
                    'X-Error-Code': error.code
                }
            }
        )
    }

    /**
     * Wrap function execution with error handling
     */
    async withErrorHandling<T>(
        operation: () => Promise<T>,
        context: {
            functionName: string
            userId?: string
            operationType?: string
        }
    ): Promise<T> {
        try {
            return await operation()
        } catch (error) {
            const momentumError: MomentumError = {
                type: ErrorType.SYSTEM_ERROR,
                code: 'OPERATION_FAILED',
                message: error instanceof Error ? error.message : 'Unknown error occurred',
                details: {
                    originalError: error instanceof Error ? error.stack : String(error),
                    context
                },
                severity: ErrorSeverity.HIGH,
                userId: context.userId,
                functionName: context.functionName,
                timestamp: new Date().toISOString()
            }

            // Log error
            await this.logError(momentumError)

            // Re-throw with additional context
            throw momentumError
        }
    }

    /**
     * Validate request body structure
     */
    validateRequestBody(
        body: any,
        requiredFields: string[],
        optionalFields: string[] = []
    ): ValidationResult {
        const errors: string[] = []

        if (!body || typeof body !== 'object') {
            errors.push('Request body must be a valid JSON object')
            return { isValid: false, errors }
        }

        // Check required fields
        for (const field of requiredFields) {
            if (!(field in body) || body[field] === null || body[field] === undefined) {
                errors.push(`Required field '${field}' is missing`)
            }
        }

        // Check for unexpected fields
        const allowedFields = [...requiredFields, ...optionalFields]
        for (const field in body) {
            if (!allowedFields.includes(field)) {
                errors.push(`Unexpected field '${field}' in request body`)
            }
        }

        return {
            isValid: errors.length === 0,
            errors
        }
    }

    /**
     * Sanitize input data
     */
    sanitizeInput(input: any): any {
        if (typeof input === 'string') {
            // Remove potentially dangerous characters
            return input.replace(/[<>\"'&]/g, '').trim()
        } else if (Array.isArray(input)) {
            return input.map(item => this.sanitizeInput(item))
        } else if (input && typeof input === 'object') {
            const sanitized: any = {}
            for (const [key, value] of Object.entries(input)) {
                sanitized[key] = this.sanitizeInput(value)
            }
            return sanitized
        }
        return input
    }

    /**
     * Check rate limits
     */
    async checkRateLimit(
        userId: string,
        operation: string,
        maxRequests: number = 100,
        windowMinutes: number = 60
    ): Promise<ValidationResult> {
        try {
            const windowStart = new Date(Date.now() - windowMinutes * 60 * 1000)

            const { count, error } = await this.supabase
                .from('momentum_error_logs')
                .select('*', { count: 'exact', head: true })
                .eq('user_id', userId)
                .eq('function_name', operation)
                .gte('created_at', windowStart.toISOString())

            if (error) {
                console.error('Rate limit check failed:', error)
                return { isValid: true, errors: [] } // Allow on error
            }

            if ((count || 0) >= maxRequests) {
                return {
                    isValid: false,
                    errors: [`Rate limit exceeded: ${maxRequests} requests per ${windowMinutes} minutes`]
                }
            }

            return { isValid: true, errors: [] }
        } catch (error) {
            console.error('Rate limit check error:', error)
            return { isValid: true, errors: [] } // Allow on error
        }
    }

    /**
     * Get system health status
     */
    async getSystemHealth(): Promise<{
        status: 'healthy' | 'degraded' | 'critical'
        errors: number
        criticalErrors: number
        lastHour: number
    }> {
        try {
            const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000)

            const { data: errorStats } = await this.supabase
                .rpc('get_error_statistics', { p_hours_back: 1 })

            const totalErrors = errorStats?.total_errors || 0
            const criticalErrors = errorStats?.critical_errors || 0

            let status: 'healthy' | 'degraded' | 'critical' = 'healthy'
            if (criticalErrors > 0) {
                status = 'critical'
            } else if (totalErrors > 10) {
                status = 'degraded'
            }

            return {
                status,
                errors: totalErrors,
                criticalErrors,
                lastHour: totalErrors
            }
        } catch (error) {
            console.error('Health check failed:', error)
            return {
                status: 'critical',
                errors: -1,
                criticalErrors: -1,
                lastHour: -1
            }
        }
    }
}

// Utility functions for common error scenarios
export function createValidationError(
    message: string,
    details?: Record<string, any>,
    userId?: string
): MomentumError {
    return {
        type: ErrorType.VALIDATION_ERROR,
        code: 'VALIDATION_FAILED',
        message,
        details,
        severity: ErrorSeverity.MEDIUM,
        userId,
        timestamp: new Date().toISOString()
    }
}

export function createCalculationError(
    message: string,
    details?: Record<string, any>,
    userId?: string
): MomentumError {
    return {
        type: ErrorType.CALCULATION_ERROR,
        code: 'CALCULATION_FAILED',
        message,
        details,
        severity: ErrorSeverity.HIGH,
        userId,
        timestamp: new Date().toISOString()
    }
}

export function createApiError(
    message: string,
    details?: Record<string, any>,
    userId?: string
): MomentumError {
    return {
        type: ErrorType.API_ERROR,
        code: 'API_ERROR',
        message,
        details,
        severity: ErrorSeverity.MEDIUM,
        userId,
        timestamp: new Date().toISOString()
    }
} 