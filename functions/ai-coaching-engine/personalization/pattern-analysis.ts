export type EngagementEvent = {
    event_type: 'app_session' | 'goal_completion' | 'momentum_change';
    timestamp: string; // ISO
    metadata: Record<string, any>;
};

export type PatternSummary = {
    engagementPeaks: string[]; // ['morning', 'evening']
    volatilityScore: number;   // 0–1
};

type TimeWindow = {
    start: Date;
    end: Date;
    events: EngagementEvent[];
};

/**
 * Analyzes user engagement patterns over a rolling 7-day window
 * Returns peak engagement periods and volatility metrics
 */
export function analyzeEngagement(events: EngagementEvent[]): PatternSummary {
    if (!events || events.length === 0) {
        return {
            engagementPeaks: [],
            volatilityScore: 0
        };
    }

    // Sort events by timestamp
    const sortedEvents = events
        .map(event => ({
            ...event,
            parsedTimestamp: new Date(event.timestamp)
        }))
        .sort((a, b) => a.parsedTimestamp.getTime() - b.parsedTimestamp.getTime());

    // Create 7-day rolling windows
    const windows = createRollingWindows(sortedEvents, 7);

    // Analyze engagement peaks by time of day
    const engagementPeaks = analyzeEngagementPeaks(sortedEvents);

    // Calculate volatility score across windows
    const volatilityScore = calculateVolatilityScore(windows);

    return {
        engagementPeaks,
        volatilityScore: Math.min(Math.max(volatilityScore, 0), 1) // Clamp to 0-1
    };
}

function createRollingWindows(events: Array<EngagementEvent & { parsedTimestamp: Date }>, windowDays: number): TimeWindow[] {
    if (events.length === 0) return [];

    const windows: TimeWindow[] = [];
    const millisecondsPerDay = 24 * 60 * 60 * 1000;
    const windowSize = windowDays * millisecondsPerDay;

    const earliestDate = events[0].parsedTimestamp;
    const latestDate = events[events.length - 1].parsedTimestamp;

    // Create overlapping 7-day windows
    for (let startTime = earliestDate.getTime(); startTime <= latestDate.getTime(); startTime += millisecondsPerDay) {
        const windowStart = new Date(startTime);
        const windowEnd = new Date(startTime + windowSize);

        const windowEvents = events.filter(event =>
            event.parsedTimestamp >= windowStart && event.parsedTimestamp < windowEnd
        );

        if (windowEvents.length > 0) {
            windows.push({
                start: windowStart,
                end: windowEnd,
                events: windowEvents
            });
        }
    }

    return windows;
}

function analyzeEngagementPeaks(events: Array<EngagementEvent & { parsedTimestamp: Date }>): string[] {
    const hourlyEngagement = Array(24).fill(0);

    // Count events by hour of day (use UTC to avoid timezone issues)
    events.forEach(event => {
        const hour = event.parsedTimestamp.getUTCHours();
        hourlyEngagement[hour]++;
    });

    // Find peak hours (above average + 1 standard deviation)
    const totalEvents = events.length;
    const avgEventsPerHour = totalEvents / 24;
    const variance = hourlyEngagement.reduce((acc, count) => acc + Math.pow(count - avgEventsPerHour, 2), 0) / 24;
    const stdDev = Math.sqrt(variance);
    const threshold = avgEventsPerHour + stdDev;

    const peaks: string[] = [];

    // Map hours to time periods
    hourlyEngagement.forEach((count, hour) => {
        if (count > threshold) {
            if (hour >= 6 && hour < 12) {
                if (!peaks.includes('morning')) peaks.push('morning');
            } else if (hour >= 12 && hour < 18) {
                if (!peaks.includes('afternoon')) peaks.push('afternoon');
            } else if (hour >= 18 && hour < 24) {
                if (!peaks.includes('evening')) peaks.push('evening');
            } else {
                if (!peaks.includes('night')) peaks.push('night');
            }
        }
    });

    return peaks;
}

function calculateVolatilityScore(windows: TimeWindow[]): number {
    if (windows.length < 2) return 0;

    // Calculate engagement rate for each window (events per day)
    const engagementRates = windows.map(window => {
        const daySpan = Math.max(1, (window.end.getTime() - window.start.getTime()) / (24 * 60 * 60 * 1000));
        return window.events.length / daySpan;
    });

    // Calculate coefficient of variation (std dev / mean)
    const mean = engagementRates.reduce((sum, rate) => sum + rate, 0) / engagementRates.length;

    if (mean === 0) return 0;

    const variance = engagementRates.reduce((acc, rate) => acc + Math.pow(rate - mean, 2), 0) / engagementRates.length;
    const stdDev = Math.sqrt(variance);

    // TODO: Refine volatility scoring algorithm once we collect real user engagement statistics
    // Current coefficient of variation may need calibration based on actual usage patterns
    return stdDev / mean; // Coefficient of variation
} 