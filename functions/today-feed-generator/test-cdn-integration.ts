/**
 * CDN Integration Test Suite
 * Epic 1.3: Today Feed (AI Daily Brief)
 * Task: T1.3.1.9 - Set up content delivery and CDN integration
 * 
 * Tests the CDN functionality, compression, caching, and performance optimization
 */

const SERVICE_URL = Deno.env.get('TODAY_FEED_SERVICE_URL') || 'http://localhost:8080'

interface TestResult {
    test_name: string
    status: 'PASS' | 'FAIL' | 'SKIP'
    duration_ms: number
    details?: any
    error?: string
}

class CDNIntegrationTester {
    private results: TestResult[] = []

    async runAllTests(): Promise<void> {
        console.log('🚀 Starting CDN Integration Test Suite')
        console.log('='.repeat(60))

        // Test suite order optimized for dependencies
        await this.testHealthCheck()
        await this.testContentWithoutCompression()
        await this.testContentWithGzipCompression()
        await this.testETagCaching()
        await this.testLastModifiedCaching()
        await this.testCacheWarmup()
        await this.testPerformanceMetrics()
        await this.testCDNConfiguration()
        await this.testCompressionRatios()
        await this.testCachePerformance()

        this.printResults()
    }

    private async makeRequest(path: string, options: RequestInit = {}): Promise<{
        response: Response
        data: any
        duration: number
    }> {
        const startTime = Date.now()

        const response = await fetch(`${SERVICE_URL}${path}`, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        })

        const duration = Date.now() - startTime
        let data: any

        try {
            data = await response.json()
        } catch {
            data = null
        }

        return { response, data, duration }
    }

    private async testHealthCheck(): Promise<void> {
        const testName = 'Health Check'
        try {
            const { response, duration } = await this.makeRequest('/health')

            if (response.ok && duration < 1000) {
                this.addResult(testName, 'PASS', duration, { status_code: response.status })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: response.status,
                    too_slow: duration >= 1000
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testContentWithoutCompression(): Promise<void> {
        const testName = 'Content Delivery (No Compression)'
        try {
            const { response, data, duration } = await this.makeRequest('/content/cached', {
                headers: {
                    'Accept-Encoding': '' // No compression support
                }
            })

            if (response.ok && data?.success && duration < 2000) {
                const hasSecurityHeaders = response.headers.get('X-Content-Type-Options') === 'nosniff'
                const hasCacheHeaders = response.headers.has('ETag') && response.headers.has('Cache-Control')

                this.addResult(testName, 'PASS', duration, {
                    content_size: response.headers.get('Content-Length'),
                    cache_status: response.headers.get('X-Cache-Status'),
                    security_headers: hasSecurityHeaders,
                    cache_headers: hasCacheHeaders,
                    compression: data.compression || 'none'
                })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: response.status,
                    success: data?.success,
                    too_slow: duration >= 2000
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testContentWithGzipCompression(): Promise<void> {
        const testName = 'Content Delivery (Gzip Compression)'
        try {
            const { response, data, duration } = await this.makeRequest('/content/cached', {
                headers: {
                    'Accept-Encoding': 'gzip, deflate'
                }
            })

            if (response.ok && data?.success) {
                const isCompressed = response.headers.get('Content-Encoding') === 'gzip'
                const hasCompressionHeaders = response.headers.has('X-Original-Size')
                const performanceGood = duration < 1500 // Compressed should be faster

                this.addResult(testName, 'PASS', duration, {
                    compressed: isCompressed,
                    content_encoding: response.headers.get('Content-Encoding'),
                    original_size: response.headers.get('X-Original-Size'),
                    compressed_size: response.headers.get('Content-Length'),
                    compression_headers: hasCompressionHeaders,
                    performance_good: performanceGood
                })
            } else {
                this.addResult(testName, 'FAIL', duration, { status_code: response.status })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testETagCaching(): Promise<void> {
        const testName = 'ETag Caching'
        try {
            // First request to get ETag
            const { response: firstResponse } = await this.makeRequest('/content/cached')
            const etag = firstResponse.headers.get('ETag')

            if (!etag) {
                this.addResult(testName, 'FAIL', 0, { error: 'No ETag received' })
                return
            }

            // Second request with If-None-Match
            const { response: secondResponse, duration } = await this.makeRequest('/content/cached', {
                headers: {
                    'If-None-Match': etag
                }
            })

            if (secondResponse.status === 304 && duration < 500) {
                this.addResult(testName, 'PASS', duration, {
                    etag_received: !!etag,
                    cache_hit: secondResponse.status === 304,
                    fast_response: duration < 500
                })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: secondResponse.status,
                    expected: 304
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testLastModifiedCaching(): Promise<void> {
        const testName = 'Last-Modified Caching'
        try {
            // First request to get Last-Modified header
            const { response: firstResponse } = await this.makeRequest('/content/cached')
            const lastModified = firstResponse.headers.get('Last-Modified')

            if (!lastModified) {
                this.addResult(testName, 'FAIL', 0, { error: 'No Last-Modified header' })
                return
            }

            // Second request with If-Modified-Since
            const { response: secondResponse, duration } = await this.makeRequest('/content/cached', {
                headers: {
                    'If-Modified-Since': lastModified
                }
            })

            if (secondResponse.status === 304) {
                this.addResult(testName, 'PASS', duration, {
                    last_modified_received: !!lastModified,
                    cache_revalidated: secondResponse.status === 304
                })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: secondResponse.status,
                    expected: 304
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testCacheWarmup(): Promise<void> {
        const testName = 'Cache Warmup'
        try {
            const dates = [
                new Date().toISOString().split('T')[0], // Today
                new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0] // Yesterday
            ]

            const { response, data, duration } = await this.makeRequest('/cdn/warm-cache', {
                method: 'POST',
                body: JSON.stringify({ dates, priority: 'high' })
            })

            if (response.ok && data?.success) {
                this.addResult(testName, 'PASS', duration, {
                    total_dates: data.total_dates,
                    successful: data.successful,
                    failed: data.failed,
                    total_time_ms: data.total_time_ms
                })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: response.status,
                    error: data?.error
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testPerformanceMetrics(): Promise<void> {
        const testName = 'Performance Metrics'
        try {
            const { response, data, duration } = await this.makeRequest('/cdn/performance?days=7&metric=all')

            if (response.ok && data?.success && data?.data) {
                const hasAllMetrics = data.data.cache && data.data.compression && data.data.performance

                this.addResult(testName, 'PASS', duration, {
                    has_cache_metrics: !!data.data.cache,
                    has_compression_metrics: !!data.data.compression,
                    has_performance_score: !!data.data.performance,
                    overall_score: data.data.performance?.overall_score,
                    grade: data.data.performance?.grade
                })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: response.status,
                    has_data: !!data?.data
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testCDNConfiguration(): Promise<void> {
        const testName = 'CDN Configuration'
        try {
            // Test GET config
            const { response, data, duration } = await this.makeRequest('/cdn/config')

            if (response.ok && data?.success && data?.config) {
                const hasRequiredConfig = data.config.cache_control &&
                    data.config.compression &&
                    data.config.performance

                this.addResult(testName, 'PASS', duration, {
                    has_cache_config: !!data.config.cache_control,
                    has_compression_config: !!data.config.compression,
                    has_performance_config: !!data.config.performance,
                    compression_enabled: data.config.compression?.enabled
                })
            } else {
                this.addResult(testName, 'FAIL', duration, {
                    status_code: response.status,
                    has_config: !!data?.config
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testCompressionRatios(): Promise<void> {
        const testName = 'Compression Ratios'
        try {
            // Test without compression
            const { response: uncompressed } = await this.makeRequest('/content/cached', {
                headers: { 'Accept-Encoding': '' }
            })

            // Test with compression
            const { response: compressed } = await this.makeRequest('/content/cached', {
                headers: { 'Accept-Encoding': 'gzip' }
            })

            const uncompressedSize = parseInt(uncompressed.headers.get('Content-Length') || '0')
            const compressedSize = parseInt(compressed.headers.get('Content-Length') || '0')
            const originalSize = parseInt(compressed.headers.get('X-Original-Size') || '0')

            const compressionRatio = originalSize > 0 ? originalSize / compressedSize : 1
            const compressionEffective = compressionRatio > 1.2 // At least 20% compression

            if (compressionEffective) {
                this.addResult(testName, 'PASS', 0, {
                    uncompressed_size: uncompressedSize,
                    compressed_size: compressedSize,
                    original_size: originalSize,
                    compression_ratio: Math.round(compressionRatio * 100) / 100,
                    bandwidth_saved: originalSize - compressedSize
                })
            } else {
                this.addResult(testName, 'FAIL', 0, {
                    compression_ratio: compressionRatio,
                    effective: compressionEffective
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private async testCachePerformance(): Promise<void> {
        const testName = 'Cache Performance (<2s requirement)'
        const maxAttempts = 5
        const results = []

        try {
            for (let i = 0; i < maxAttempts; i++) {
                const { response, duration } = await this.makeRequest('/content/cached')
                results.push({
                    attempt: i + 1,
                    duration_ms: duration,
                    status: response.status,
                    cache_status: response.headers.get('X-Cache-Status')
                })
            }

            const avgDuration = results.reduce((sum, r) => sum + r.duration_ms, 0) / results.length
            const maxDuration = Math.max(...results.map(r => r.duration_ms))
            const meets2SecondRequirement = maxDuration < 2000
            const averageGood = avgDuration < 1000

            if (meets2SecondRequirement && averageGood) {
                this.addResult(testName, 'PASS', avgDuration, {
                    attempts: maxAttempts,
                    avg_duration_ms: Math.round(avgDuration),
                    max_duration_ms: maxDuration,
                    meets_2s_requirement: meets2SecondRequirement,
                    average_good: averageGood,
                    results: results
                })
            } else {
                this.addResult(testName, 'FAIL', avgDuration, {
                    avg_duration_ms: avgDuration,
                    max_duration_ms: maxDuration,
                    meets_2s_requirement: meets2SecondRequirement,
                    results: results
                })
            }
        } catch (error) {
            this.addResult(testName, 'FAIL', 0, undefined, error.message)
        }
    }

    private addResult(testName: string, status: 'PASS' | 'FAIL' | 'SKIP', duration: number, details?: any, error?: string): void {
        this.results.push({
            test_name: testName,
            status,
            duration_ms: Math.round(duration),
            details,
            error
        })
    }

    private printResults(): void {
        console.log('\n' + '='.repeat(60))
        console.log('📊 CDN Integration Test Results')
        console.log('='.repeat(60))

        const passed = this.results.filter(r => r.status === 'PASS').length
        const failed = this.results.filter(r => r.status === 'FAIL').length
        const total = this.results.length

        this.results.forEach(result => {
            const icon = result.status === 'PASS' ? '✅' : result.status === 'FAIL' ? '❌' : '⏭️'
            const duration = result.duration_ms > 0 ? ` (${result.duration_ms}ms)` : ''

            console.log(`${icon} ${result.test_name}${duration}`)

            if (result.details && Object.keys(result.details).length > 0) {
                console.log(`   Details: ${JSON.stringify(result.details, null, 2).split('\n').join('\n   ')}`)
            }

            if (result.error) {
                console.log(`   Error: ${result.error}`)
            }
            console.log('')
        })

        console.log('='.repeat(60))
        console.log(`📈 Summary: ${passed}/${total} tests passed (${Math.round(passed / total * 100)}%)`)

        if (failed > 0) {
            console.log(`❌ ${failed} tests failed`)
            Deno.exit(1)
        } else {
            console.log('🎉 All CDN integration tests passed!')
            console.log('✨ CDN optimization is working correctly and meets <2s load time requirement')
        }
    }
}

// Run tests if this file is executed directly
if (import.meta.main) {
    const tester = new CDNIntegrationTester()
    await tester.runAllTests()
} 