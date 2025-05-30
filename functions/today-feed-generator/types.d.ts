// Today Feed Content Types
export interface TodayFeedContent {
    id?: number
    content_date: string // ISO date string (YYYY-MM-DD)
    title: string // max 60 characters
    summary: string // max 200 characters
    content_url?: string
    external_link?: string
    topic_category: HealthTopic
    ai_confidence_score: number // 0.0 to 1.0
    created_at?: string
    updated_at?: string
}

export type HealthTopic =
    | 'nutrition'
    | 'exercise'
    | 'sleep'
    | 'stress'
    | 'prevention'
    | 'lifestyle'

// Medical Safety Review Types
export interface ContentReviewItem {
    id?: number
    content_id?: number
    content_date: string
    title: string
    summary: string
    topic_category: HealthTopic
    ai_confidence_score: number
    safety_score: number
    flagged_issues: string[]
    review_status: ReviewStatus
    reviewer_id?: string
    reviewer_email?: string
    review_notes?: string
    reviewed_at?: string
    escalated_at?: string
    escalation_reason?: string
    created_at?: string
    updated_at?: string
}

export type ReviewStatus =
    | 'pending_review'
    | 'approved'
    | 'rejected'
    | 'escalated'
    | 'auto_approved'

export interface ReviewAction {
    action: 'approve' | 'reject' | 'escalate'
    reviewer_id: string
    reviewer_email: string
    notes?: string
    escalation_reason?: string
}

export interface ReviewNotification {
    type: 'new_content_flagged' | 'content_approved' | 'content_rejected' | 'content_escalated'
    content_id: number
    content_date: string
    title: string
    reviewer_email?: string
    escalation_reason?: string
    timestamp: string
}

// Vertex AI Integration Types
export interface ContentGenerationRequest {
    topic: HealthTopic
    date: string
    target_length: number
    tone: 'conversational' | 'educational' | 'motivational'
}

export interface VertexAIResponse {
    title: string
    summary: string
    confidence_score: number
    external_references?: string[]
}

// Content Quality Validation
export interface QualityValidationResult {
    is_valid: boolean
    confidence_score: number
    safety_score: number
    readability_score: number
    engagement_score: number
    issues: string[]
    requires_review?: boolean
}

// API Response Types
export interface TodayFeedApiResponse {
    success: boolean
    data?: TodayFeedContent
    error?: string
    cached_at?: string
    expires_at?: string
}

export interface ContentGenerationResult {
    success: boolean
    content?: TodayFeedContent
    validation_result?: QualityValidationResult
    error?: string
    requires_review?: boolean
    review_item_id?: number
    is_fallback?: boolean // Indicates if fallback content was used
}

export interface ReviewQueueResponse {
    success: boolean
    pending_reviews: ContentReviewItem[]
    total_count: number
    error?: string
}

export interface ReviewActionResponse {
    success: boolean
    updated_item?: ContentReviewItem
    published_content?: TodayFeedContent
    error?: string
}

// Content Versioning Types
export interface ContentVersion {
    id?: number
    content_id: number
    version_number: number
    title: string
    summary: string
    content_url?: string
    external_link?: string
    topic_category: HealthTopic
    ai_confidence_score: number
    change_type: 'initial' | 'update' | 'rollback' | 'regeneration'
    change_reason?: string
    changed_by: string
    is_active: boolean
    created_at?: string
}

export interface ContentChangeLog {
    id?: number
    content_id: number
    from_version?: number
    to_version: number
    action_type: 'create' | 'update' | 'rollback' | 'publish' | 'unpublish'
    changed_by: string
    change_notes?: string
    old_values?: Record<string, any>
    new_values?: Record<string, any>
    created_at?: string
}

export interface ContentDeliveryOptimization {
    id?: number
    content_id: number
    etag: string
    last_modified: string
    cache_control: string
    compression_type: 'gzip' | 'br' | 'none'
    content_size?: number
    cdn_url?: string
    cache_hits: number
    cache_misses: number
    updated_at?: string
}

// Extended content type with version info
export interface ContentWithVersions extends TodayFeedContent {
    current_version?: number
    last_change_type?: string
    last_change_reason?: string
    last_changed_by?: string
    etag?: string
    cache_control?: string
    last_modified?: string
    content_size?: number
    cdn_url?: string
    total_versions?: number
}

// Version management request/response types
export interface CreateVersionRequest {
    content_id: number
    change_type: 'initial' | 'update' | 'rollback' | 'regeneration'
    change_reason?: string
    changed_by?: string
}

export interface RollbackVersionRequest {
    content_id: number
    target_version: number
    rollback_reason?: string
    changed_by?: string
}

export interface VersionManagementResponse {
    success: boolean
    version_id?: number
    content?: TodayFeedContent
    version_info?: ContentVersion
    error?: string
}

export interface VersionHistoryResponse {
    success: boolean
    versions: ContentVersion[]
    change_log: ContentChangeLog[]
    total_versions: number
    current_version?: number
    error?: string
}

// Content delivery response with caching headers
export interface CachedContentResponse {
    success: boolean
    data: TodayFeedContent
    cached_at: string
    expires_at: string
    etag?: string
    last_modified?: string
    cache_control?: string
    content_size?: number
    cache_status: 'hit' | 'miss' | 'stale' | 'revalidated'
    compression?: 'gzip' | 'br' | 'none'
    cdn_url?: string
}

// Enhanced Content Moderation and Approval Workflow Types

// Reviewer Management
export interface Reviewer {
    id: string
    email: string
    name: string
    role: 'medical_reviewer' | 'content_reviewer' | 'senior_reviewer' | 'admin'
    specializations: string[]
    is_active: boolean
    max_reviews_per_day: number
    current_reviews_assigned: number
    last_activity?: string
    performance_rating?: number
    created_at?: string
}

// Batch Operations
export interface BatchReviewAction {
    action: 'approve' | 'reject' | 'escalate' | 'assign'
    review_item_ids: number[]
    reviewer_id: string
    reviewer_email: string
    notes?: string
    escalation_reason?: string
    assignee_id?: string // For assignment operations
}

export interface BatchOperationResult {
    success: boolean
    total_items: number
    successful_operations: number
    failed_operations: BatchOperationError[]
    updated_items: ContentReviewItem[]
}

export interface BatchOperationError {
    review_item_id: number
    error: string
    error_code: string
}

// Enhanced Review Assignment
export interface ReviewAssignment {
    id?: number
    review_item_id: number
    assigned_to: string
    assigned_by: string
    assigned_at: string
    due_date?: string
    priority: 'low' | 'medium' | 'high' | 'urgent'
    status: 'assigned' | 'accepted' | 'declined' | 'reassigned'
    escalation_level?: number
}

// Workflow Automation
export interface AutoApprovalRule {
    id?: number
    name: string
    description: string
    is_active: boolean
    conditions: AutoApprovalCondition[]
    actions: AutoApprovalAction[]
    created_by: string
    created_at?: string
    last_triggered?: string
    trigger_count?: number
}

export interface AutoApprovalCondition {
    field: 'safety_score' | 'ai_confidence_score' | 'topic_category' | 'flagged_issues_count'
    operator: 'gt' | 'gte' | 'lt' | 'lte' | 'eq' | 'ne' | 'in' | 'not_in'
    value: string | number | string[]
}

export interface AutoApprovalAction {
    type: 'auto_approve' | 'assign_reviewer' | 'escalate' | 'notify'
    parameters: Record<string, any>
}

// Enhanced Analytics
export interface ReviewAnalytics {
    period_start: string
    period_end: string
    total_content_generated: number
    total_reviews_required: number
    auto_approved_count: number
    manual_approved_count: number
    rejected_count: number
    escalated_count: number
    average_review_time_hours: number
    reviewer_performance: ReviewerPerformance[]
    topic_category_breakdown: TopicReviewBreakdown[]
    safety_score_distribution: ScoreDistribution[]
    workflow_efficiency: WorkflowEfficiencyMetrics
}

export interface ReviewerPerformance {
    reviewer_id: string
    reviewer_email: string
    reviews_completed: number
    average_review_time_hours: number
    approval_rate: number
    rejection_rate: number
    escalation_rate: number
    quality_score: number
    workload_percentage: number
}

export interface TopicReviewBreakdown {
    topic_category: HealthTopic
    total_content: number
    auto_approved: number
    manual_reviews: number
    rejection_rate: number
    average_safety_score: number
}

export interface ScoreDistribution {
    score_range: string // e.g., "0.8-0.85"
    count: number
    percentage: number
}

export interface WorkflowEfficiencyMetrics {
    average_time_to_review_hours: number
    sla_compliance_rate: number // Percentage meeting review SLA
    bottleneck_analysis: BottleneckMetric[]
    automation_rate: number // Percentage auto-approved
    escalation_effectiveness: number
}

export interface BottleneckMetric {
    stage: 'assignment' | 'initial_review' | 'escalation' | 'final_approval'
    average_delay_hours: number
    items_affected: number
    improvement_suggestions: string[]
}

// Enhanced Notification System
export interface EnhancedReviewNotification {
    id?: number
    type: 'assignment' | 'reminder' | 'escalation' | 'sla_breach' | 'batch_complete' | 'workflow_alert'
    review_item_id?: number
    batch_operation_id?: string
    recipient_id: string
    recipient_email: string
    priority: 'low' | 'medium' | 'high' | 'urgent'
    title: string
    message: string
    action_required: boolean
    action_url?: string
    scheduled_for?: string
    sent: boolean
    sent_at?: string
    read: boolean
    read_at?: string
    expires_at?: string
    created_at?: string
}

// Admin Dashboard Integration
export interface AdminDashboardData {
    overview: {
        pending_reviews: number
        overdue_reviews: number
        active_reviewers: number
        auto_approval_rate: number
        average_review_time: number
    }
    recent_activity: RecentActivityItem[]
    alert_notifications: AdminAlert[]
    performance_summary: ReviewAnalytics
    system_health: SystemHealthMetric[]
}

export interface RecentActivityItem {
    id: string
    type: 'content_reviewed' | 'reviewer_assigned' | 'content_escalated' | 'auto_approved'
    description: string
    reviewer_email?: string
    content_title?: string
    timestamp: string
    severity: 'info' | 'warning' | 'error'
}

export interface AdminAlert {
    id: string
    type: 'sla_breach' | 'reviewer_overload' | 'quality_decline' | 'system_error'
    severity: 'low' | 'medium' | 'high' | 'critical'
    title: string
    description: string
    action_required: boolean
    created_at: string
    resolved: boolean
    resolved_at?: string
}

export interface SystemHealthMetric {
    component: 'content_generation' | 'review_queue' | 'notification_system' | 'auto_approval'
    status: 'healthy' | 'degraded' | 'down'
    last_check: string
    error_rate: number
    response_time_ms?: number
}

// API Response Types for Enhanced Features
export interface BatchOperationResponse {
    success: boolean
    operation_id: string
    result: BatchOperationResult
    error?: string
}

export interface ReviewAssignmentResponse {
    success: boolean
    assignment: ReviewAssignment
    notification_sent: boolean
    error?: string
}

export interface AutoApprovalRulesResponse {
    success: boolean
    rules: AutoApprovalRule[]
    total_count: number
    error?: string
}

export interface ReviewAnalyticsResponse {
    success: boolean
    analytics: ReviewAnalytics
    error?: string
}

export interface AdminDashboardResponse {
    success: boolean
    dashboard_data: AdminDashboardData
    error?: string
}

// Content Analytics and Monitoring Types (T1.3.1.10)
export interface ContentAnalytics {
    period_start: string
    period_end: string
    total_content_published: number
    total_user_interactions: number
    unique_users_engaged: number
    overall_engagement_rate: number
    average_session_duration: number
    content_performance: ContentPerformanceMetrics[]
    topic_performance: TopicPerformanceMetrics[]
    user_engagement_trends: EngagementTrendData[]
    quality_metrics: ContentQualityMetrics
    kpi_summary: KPISummary
}

export interface ContentPerformanceMetrics {
    content_id: number
    content_date: string
    title: string
    topic_category: string
    ai_confidence_score: number
    total_views: number
    total_clicks: number
    total_shares: number
    total_bookmarks: number
    unique_viewers: number
    engagement_rate: number
    avg_session_duration: number
    momentum_points_awarded: number
    performance_score: number
    quality_rating: number
}

export interface TopicPerformanceMetrics {
    topic_category: string
    total_content_pieces: number
    total_views: number
    total_interactions: number
    average_engagement_rate: number
    average_session_duration: number
    momentum_points_generated: number
    user_preference_score: number
    content_quality_average: number
}

export interface EngagementTrendData {
    date: string
    total_views: number
    total_clicks: number
    total_shares: number
    total_bookmarks: number
    unique_users: number
    engagement_rate: number
    momentum_points_awarded: number
}

export interface ContentQualityMetrics {
    average_ai_confidence: number
    content_safety_score: number
    user_satisfaction_rating: number
    content_freshness_score: number
    topic_diversity_score: number
    medical_accuracy_compliance: number
}

export interface KPISummary {
    daily_engagement_rate: number
    target_engagement_rate: number
    engagement_rate_trend: 'increasing' | 'decreasing' | 'stable'
    content_load_time_avg: number
    target_load_time: number
    load_time_compliance: number
    momentum_integration_success_rate: number
    content_quality_score: number
    user_retention_rate: number
    content_effectiveness_score: number
}

export interface UserEngagementMetrics {
    user_id: string
    total_interactions: number
    consecutive_days_engaged: number
    favorite_topics: string[]
    average_session_duration: number
    momentum_points_earned: number
    last_interaction: string
    engagement_level: 'low' | 'medium' | 'high'
}

export interface ContentAnalyticsRequest {
    period_days?: number
    include_user_details?: boolean
    topic_filter?: string[]
    start_date?: string
    end_date?: string
    metrics_type?: 'summary' | 'detailed' | 'trends'
}

export interface ContentAnalyticsResponse {
    success: boolean
    analytics: ContentAnalytics
    error?: string
}

export interface ContentPerformanceResponse {
    success: boolean
    performance_data: ContentPerformanceMetrics[]
    error?: string
}

export interface UserEngagementResponse {
    success: boolean
    engagement_data: UserEngagementMetrics[]
    error?: string
}

export interface ContentMonitoringAlert {
    id: string
    alert_type: 'low_engagement' | 'quality_issue' | 'load_time_violation' | 'user_feedback'
    severity: 'low' | 'medium' | 'high' | 'critical'
    content_id?: number
    message: string
    details: Record<string, any>
    created_at: string
    resolved: boolean
    resolved_at?: string
}

export interface MonitoringDashboard {
    current_status: 'healthy' | 'warning' | 'critical'
    active_alerts: ContentMonitoringAlert[]
    real_time_metrics: {
        current_users_engaged: number
        todays_content_views: number
        current_engagement_rate: number
        average_load_time: number
        momentum_points_awarded_today: number
    }
    performance_summary: {
        last_24h_engagement: number
        last_7d_avg_engagement: number
        content_quality_trend: 'improving' | 'declining' | 'stable'
        user_satisfaction_score: number
    }
}

export interface MonitoringDashboardResponse {
    success: boolean
    dashboard: MonitoringDashboard
    error?: string
}

export interface ContentOptimizationInsights {
    recommended_topics: string[]
    optimal_posting_times: string[]
    content_length_recommendations: {
        title_length: number
        summary_length: number
    }
    engagement_improvement_suggestions: string[]
    quality_enhancement_tips: string[]
}

export interface OptimizationInsightsResponse {
    success: boolean
    insights: ContentOptimizationInsights
    error?: string
} 