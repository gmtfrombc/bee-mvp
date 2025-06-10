/**
 * Epic 3.1 Integration Interface
 * Data contracts for Enhanced Cross-Patient Learning
 *
 * This interface defines the data structures and contracts that Epic 3.1
 * will use to consume cross-patient learning patterns from the current
 * personalization engine foundation.
 */

export interface Epic31DataContract {
  // Pattern aggregation data contract
  patternAggregates: {
    queryInterface: PatternAggregateQuery
    responseFormat: PatternAggregateResponse
    privacyConstraints: PrivacyConstraints
  }

  // Insight generation data contract
  insightGeneration: {
    inputFormat: InsightGenerationInput
    outputFormat: InsightGenerationOutput
    confidenceThresholds: ConfidenceThresholds
  }

  // Real-time learning integration
  realtimeLearning: {
    eventStreaming: EventStreamingContract
    adaptiveAdjustment: AdaptiveAdjustmentContract
  }
}

/**
 * Pattern Aggregate Query Interface
 * Defines how Epic 3.1 will query aggregated patterns
 */
export interface PatternAggregateQuery {
  timeRange: {
    startWeek: string // ISO date string
    endWeek: string // ISO date string
  }
  patternTypes:
    (
      | 'engagement_peak'
      | 'volatility_trend'
      | 'persona_effectiveness'
      | 'intervention_timing'
      | 'response_frequency'
    )[]
  momentumStates?: ('Rising' | 'Steady' | 'NeedsCare')[]
  minConfidenceLevel?: number // 0.0 to 1.0
  minCohortSize?: number // Minimum users for privacy
}

/**
 * Pattern Aggregate Response Format
 * Standardized format for Epic 3.1 consumption
 */
export interface PatternAggregateResponse {
  patterns: {
    id: string
    type: string
    data: {
      commonPatterns: string[]
      effectivenessScores: Record<string, number>
      recommendedApproaches: string[]
      metadata: {
        cohortSize: number
        confidenceLevel: number
        weeklyTimestamp: string
        momentumState?: string
      }
    }
  }[]
  aggregationMetadata: {
    totalPatterns: number
    avgConfidenceLevel: number
    privacyCompliant: boolean
    queryTimestamp: string
  }
}

/**
 * Privacy Constraints for Cross-Patient Learning
 * Ensures Epic 3.1 respects privacy requirements
 */
export interface PrivacyConstraints {
  minimumUserThreshold: number // Minimum 5 users for any pattern
  anonymizationLevel: 'full' | 'partial'
  dataRetentionWeeks: number // How long to keep aggregated data
  excludedDataTypes: string[] // Types of data not to aggregate
  consentRequirements: {
    explicitConsent: boolean
    optOutMechanism: boolean
    dataUsageTransparency: boolean
  }
}

/**
 * Insight Generation Input Format
 * How Epic 3.1 will request insights
 */
export interface InsightGenerationInput {
  targetWeek: string // ISO date string
  focusAreas: ('timing' | 'personas' | 'interventions' | 'engagement')[]
  userSegment?: string // Optional user segmentation
  contextualFactors?: {
    seasonality?: boolean
    eventDriven?: boolean
    cohortSpecific?: boolean
  }
}

/**
 * Insight Generation Output Format
 * Standardized insights for Epic 3.1
 */
export interface InsightGenerationOutput {
  insights: {
    id: string
    type: string
    recommendation: string
    data: Record<string, any>
    confidence: number
    supportingEvidence: string[]
    applicableWeek: string
    expectedImpact: {
      effectivenessImprovement: number // Expected % improvement
      confidenceInterval: [number, number]
    }
  }[]
  generationMetadata: {
    processingTime: number
    dataQuality: number
    innovationScore: number // How novel the insights are
    generatedAt: string
  }
}

/**
 * Confidence Thresholds for Epic 3.1 Integration
 */
export interface ConfidenceThresholds {
  minPatternConfidence: number // Minimum confidence for pattern inclusion
  minInsightConfidence: number // Minimum confidence for insight generation
  highConfidenceThreshold: number // Threshold for high-confidence insights
  actionableThreshold: number // Threshold for actionable recommendations
}

/**
 * Event Streaming Contract for Real-time Learning
 */
export interface EventStreamingContract {
  streamingEndpoint: string
  eventTypes: ('effectiveness_feedback' | 'pattern_update' | 'insight_generated')[]
  payloadFormat: {
    eventType: string
    timestamp: string
    data: Record<string, any>
    metadata: {
      source: string
      version: string
      confidenceLevel: number
    }
  }
  deliveryGuarantees: {
    atLeastOnce: boolean
    ordering: boolean
    durability: boolean
  }
}

/**
 * Adaptive Adjustment Contract
 * How Epic 3.1 will provide feedback for continuous learning
 */
export interface AdaptiveAdjustmentContract {
  feedbackFormat: {
    patternId: string
    adjustmentType: 'effectiveness' | 'confidence' | 'recommendation'
    adjustmentValue: number
    reasonCode: string
    timestamp: string
  }
  adjustmentEndpoint: string
  batchProcessing: {
    enabled: boolean
    batchSize: number
    processingInterval: number // minutes
  }
}

/**
 * Epic 3.1 Integration Service Interface
 * Service contract for cross-patient learning integration
 */
export interface Epic31IntegrationService {
  // Pattern querying
  queryPatterns(query: PatternAggregateQuery): Promise<PatternAggregateResponse>

  // Insight generation
  generateInsights(input: InsightGenerationInput): Promise<InsightGenerationOutput>

  // Real-time streaming
  startPatternStream(config: EventStreamingContract): Promise<void>
  stopPatternStream(): Promise<void>

  // Adaptive feedback
  submitFeedback(feedback: AdaptiveAdjustmentContract['feedbackFormat'][]): Promise<void>

  // Health and status
  getIntegrationHealth(): Promise<{
    status: 'healthy' | 'degraded' | 'unhealthy'
    lastUpdate: string
    dataQuality: number
    privacyCompliance: boolean
  }>
}

/**
 * Migration Utilities for Epic 3.1 Transition
 */
export interface Epic31MigrationUtils {
  // Data migration
  migratePatternAggregates(fromVersion: string, toVersion: string): Promise<{
    success: boolean
    migratedRecords: number
    errors: string[]
  }>

  // Schema evolution
  validateSchemaCompatibility(newSchema: any): Promise<{
    compatible: boolean
    requiredChanges: string[]
    breakingChanges: string[]
  }>

  // Rollback capabilities
  rollbackToVersion(version: string): Promise<{
    success: boolean
    rollbackTimestamp: string
  }>
}

/**
 * Epic 3.1 Configuration Interface
 * Configuration settings for the enhanced learning system
 */
export interface Epic31Configuration {
  // Learning parameters
  learning: {
    patternUpdateFrequency: number // hours
    insightGenerationSchedule: string // cron expression
    adaptiveLearningRate: number // 0.0 to 1.0
    crossValidationEnabled: boolean
  }

  // Privacy and security
  privacy: {
    anonymizationLevel: 'full' | 'partial'
    dataRetentionDays: number
    consentCheckEnabled: boolean
    auditLogEnabled: boolean
  }

  // Performance settings
  performance: {
    maxConcurrentQueries: number
    cacheTimeoutMinutes: number
    batchProcessingSize: number
    resourceLimits: {
      maxMemoryMB: number
      maxProcessingTimeSeconds: number
    }
  }

  // Integration settings
  integration: {
    apiVersion: string
    compatibilityMode: boolean
    fallbackToV1: boolean
    monitoringEnabled: boolean
  }
}

/**
 * Default Epic 3.1 Configuration
 * Sensible defaults for the enhanced learning system
 */
export const DEFAULT_EPIC31_CONFIG: Epic31Configuration = {
  learning: {
    patternUpdateFrequency: 24, // Daily updates
    insightGenerationSchedule: '0 2 * * 1', // Weekly on Monday at 2 AM
    adaptiveLearningRate: 0.1, // Conservative learning rate
    crossValidationEnabled: true,
  },
  privacy: {
    anonymizationLevel: 'full',
    dataRetentionDays: 90, // 3 months
    consentCheckEnabled: true,
    auditLogEnabled: true,
  },
  performance: {
    maxConcurrentQueries: 10,
    cacheTimeoutMinutes: 60,
    batchProcessingSize: 100,
    resourceLimits: {
      maxMemoryMB: 512,
      maxProcessingTimeSeconds: 30,
    },
  },
  integration: {
    apiVersion: '3.1',
    compatibilityMode: true,
    fallbackToV1: true,
    monitoringEnabled: true,
  },
}
