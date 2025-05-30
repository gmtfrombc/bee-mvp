#!/usr/bin/env -S deno run --allow-net --allow-env
/**
 * Test script for Today Feed Content Versioning System
 * 
 * This script tests all the versioning API endpoints to ensure they work correctly.
 * Run this after deploying the versioning system to validate functionality.
 */

const BASE_URL = Deno.env.get('TODAY_FEED_SERVICE_URL') || 'http://localhost:8080'

interface TestResult {
    test: string
    passed: boolean
    error?: string
    response?: any
}

const results: TestResult[] = []

function addResult(test: string, passed: boolean, error?: string, response?: any) {
    results.push({ test, passed, error, response })
    const status = passed ? '✅ PASS' : '❌ FAIL'
    console.log(`${status}: ${test}`)
    if (error) console.log(`   Error: ${error}`)
}

async function makeRequest(path: string, options: RequestInit = {}) {
    try {
        const response = await fetch(`${BASE_URL}${path}`, {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        })

        const text = await response.text()
        let data
        try {
            data = JSON.parse(text)
        } catch {
            data = text
        }

        return { response, data }
    } catch (error) {
        throw new Error(`Network error: ${error.message}`)
    }
}

async function testHealthCheck() {
    try {
        const { response, data } = await makeRequest('/health')

        if (response.ok && data.status) {
            addResult('Health Check', true, undefined, data)
        } else {
            addResult('Health Check', false, 'Service not healthy', data)
        }
    } catch (error) {
        addResult('Health Check', false, error.message)
    }
}

async function testGetVersionHistory() {
    try {
        // Test without content_id (should fail)
        const { response: badResponse } = await makeRequest('/versions/history')

        if (badResponse.status === 400) {
            addResult('Version History - Missing Content ID Validation', true)
        } else {
            addResult('Version History - Missing Content ID Validation', false, 'Should return 400 for missing content_id')
        }

        // Test with content_id (might not exist, but should handle gracefully)
        const { response, data } = await makeRequest('/versions/history?content_id=999')

        if (response.ok && data.success !== undefined) {
            addResult('Version History - API Structure', true, undefined, data)
        } else {
            addResult('Version History - API Structure', false, 'Invalid response structure', data)
        }
    } catch (error) {
        addResult('Version History', false, error.message)
    }
}

async function testCreateVersion() {
    try {
        // Test without request body (should fail)
        const { response: badResponse } = await makeRequest('/versions/create', {
            method: 'GET' // Wrong method
        })

        if (badResponse.status === 405) {
            addResult('Create Version - Method Validation', true)
        } else {
            addResult('Create Version - Method Validation', false, 'Should return 405 for wrong method')
        }

        // Test with invalid data (should fail)
        const { response, data } = await makeRequest('/versions/create', {
            method: 'POST',
            body: JSON.stringify({}) // Missing required fields
        })

        if (response.status === 400 && data.success === false) {
            addResult('Create Version - Input Validation', true)
        } else {
            addResult('Create Version - Input Validation', false, 'Should validate required fields', data)
        }
    } catch (error) {
        addResult('Create Version', false, error.message)
    }
}

async function testRollbackVersion() {
    try {
        // Test wrong method
        const { response: badResponse } = await makeRequest('/versions/rollback', {
            method: 'GET'
        })

        if (badResponse.status === 405) {
            addResult('Rollback Version - Method Validation', true)
        } else {
            addResult('Rollback Version - Method Validation', false, 'Should return 405 for wrong method')
        }

        // Test with invalid data
        const { response, data } = await makeRequest('/versions/rollback', {
            method: 'POST',
            body: JSON.stringify({ content_id: 'invalid' }) // Missing target_version
        })

        if (response.status === 400 && data.success === false) {
            addResult('Rollback Version - Input Validation', true)
        } else {
            addResult('Rollback Version - Input Validation', false, 'Should validate required fields', data)
        }
    } catch (error) {
        addResult('Rollback Version', false, error.message)
    }
}

async function testCachedContent() {
    try {
        // Test basic cached content endpoint
        const { response, data } = await makeRequest('/content/cached')

        // Should return either 200 with content or 404 if no content exists
        if (response.status === 200 || response.status === 404) {
            if (response.status === 200 && data.success !== undefined) {
                addResult('Cached Content - API Structure', true, undefined, data)
            } else if (response.status === 404) {
                addResult('Cached Content - No Content Handling', true, 'Correctly handles missing content')
            } else {
                addResult('Cached Content - Response Structure', false, 'Invalid response structure', data)
            }
        } else {
            addResult('Cached Content', false, `Unexpected status: ${response.status}`, data)
        }

        // Test with specific date
        const { response: dateResponse } = await makeRequest('/content/cached?date=2024-12-29')

        if (dateResponse.status === 200 || dateResponse.status === 404) {
            addResult('Cached Content - Date Parameter', true)
        } else {
            addResult('Cached Content - Date Parameter', false, `Unexpected status: ${dateResponse.status}`)
        }
    } catch (error) {
        addResult('Cached Content', false, error.message)
    }
}

async function testDeliveryStats() {
    try {
        const { response, data } = await makeRequest('/delivery/stats')

        if (response.ok && data.success !== undefined) {
            addResult('Delivery Stats - Basic Response', true, undefined, data)

            // Check response structure
            if (data.summary && typeof data.period_days === 'number') {
                addResult('Delivery Stats - Response Structure', true)
            } else {
                addResult('Delivery Stats - Response Structure', false, 'Missing required fields in response')
            }
        } else {
            addResult('Delivery Stats', false, 'Invalid response', data)
        }

        // Test with days parameter
        const { response: daysResponse } = await makeRequest('/delivery/stats?days=30')

        if (daysResponse.ok) {
            addResult('Delivery Stats - Days Parameter', true)
        } else {
            addResult('Delivery Stats - Days Parameter', false, 'Days parameter not working')
        }
    } catch (error) {
        addResult('Delivery Stats', false, error.message)
    }
}

async function testCacheHeaders() {
    try {
        const { response } = await makeRequest('/content/cached?date=2024-12-29')

        // Check for proper CORS headers
        const corsHeaders = ['access-control-allow-origin', 'access-control-allow-methods']
        let corsHeadersPresent = true

        for (const header of corsHeaders) {
            if (!response.headers.get(header)) {
                corsHeadersPresent = false
                break
            }
        }

        if (corsHeadersPresent) {
            addResult('CORS Headers', true)
        } else {
            addResult('CORS Headers', false, 'Missing CORS headers')
        }

        // Check content type
        const contentType = response.headers.get('content-type')
        if (contentType && contentType.includes('application/json')) {
            addResult('Content Type Headers', true)
        } else {
            addResult('Content Type Headers', false, 'Missing or incorrect content-type header')
        }
    } catch (error) {
        addResult('Cache Headers', false, error.message)
    }
}

async function runTests() {
    console.log('🧪 Testing Today Feed Versioning System')
    console.log(`📍 Service URL: ${BASE_URL}`)
    console.log('='.repeat(50))

    await testHealthCheck()
    await testGetVersionHistory()
    await testCreateVersion()
    await testRollbackVersion()
    await testCachedContent()
    await testDeliveryStats()
    await testCacheHeaders()

    console.log('='.repeat(50))

    const passed = results.filter(r => r.passed).length
    const total = results.length
    const percentage = Math.round((passed / total) * 100)

    console.log(`📊 Test Results: ${passed}/${total} tests passed (${percentage}%)`)

    if (passed === total) {
        console.log('🎉 All tests passed! Versioning system is working correctly.')
    } else {
        console.log('⚠️  Some tests failed. Check the errors above.')

        const failed = results.filter(r => !r.passed)
        console.log('\n❌ Failed Tests:')
        failed.forEach(test => {
            console.log(`   - ${test.test}: ${test.error || 'Unknown error'}`)
        })
    }

    return passed === total
}

if (import.meta.main) {
    const success = await runTests()
    Deno.exit(success ? 0 : 1)
} 