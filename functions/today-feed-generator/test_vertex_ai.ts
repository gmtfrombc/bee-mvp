#!/usr/bin/env -S deno run --allow-env --allow-net

/**
 * Test script for Vertex AI integration
 * Run with: deno run --allow-env --allow-net test_vertex_ai.ts
 */

import { ContentGenerationRequest } from './types.d.ts'

// Mock environment variables for testing
const VERTEX_AI_LOCATION = 'us-central1'
const GCP_PROJECT_ID = Deno.env.get('GCP_PROJECT_ID') || 'your-project-id'
const GOOGLE_APPLICATION_CREDENTIALS = Deno.env.get('GOOGLE_APPLICATION_CREDENTIALS')

if (!GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('❌ GOOGLE_APPLICATION_CREDENTIALS environment variable not set')
    console.error('Please set up your service account credentials first')
    Deno.exit(1)
}

if (!GCP_PROJECT_ID || GCP_PROJECT_ID === 'your-project-id') {
    console.error('❌ GCP_PROJECT_ID environment variable not set')
    console.error('Please set your Google Cloud project ID')
    Deno.exit(1)
}

/**
 * Test the Vertex AI content generation
 */
async function testVertexAI() {
    console.log('🧪 Testing Vertex AI integration...\n')

    const testRequest: ContentGenerationRequest = {
        topic: 'nutrition',
        date: new Date().toISOString().split('T')[0],
        target_length: 200,
        tone: 'conversational'
    }

    console.log('📝 Test request:', testRequest)
    console.log('🌍 Project ID:', GCP_PROJECT_ID)
    console.log('📍 Location:', VERTEX_AI_LOCATION)
    console.log()

    try {
        // Test access token generation
        console.log('🔑 Testing Google Cloud authentication...')
        const accessToken = await getGoogleCloudAccessToken()
        console.log('✅ Access token obtained successfully')
        console.log()

        // Test Vertex AI API call
        console.log('🤖 Testing Vertex AI content generation...')
        const aiContent = await callVertexAI(testRequest, accessToken)

        if (aiContent) {
            console.log('✅ Content generated successfully!')
            console.log('📄 Generated content:')
            console.log(`   Title: "${aiContent.title}"`)
            console.log(`   Summary: "${aiContent.summary}"`)
            console.log(`   Confidence: ${aiContent.confidence_score}`)
            console.log()
        } else {
            console.log('❌ Failed to generate content')
        }

    } catch (error) {
        console.error('❌ Test failed:', error.message)
        console.error('Stack trace:', error.stack)
    }
}

// Simplified functions for testing (copied from main service)
async function getGoogleCloudAccessToken(): Promise<string> {
    const credentials = JSON.parse(GOOGLE_APPLICATION_CREDENTIALS!)
    const jwt = await createJWTForGoogleCloud(credentials)

    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt,
        }),
    })

    if (!tokenResponse.ok) {
        const errorText = await tokenResponse.text()
        throw new Error(`Failed to get access token: ${tokenResponse.status} - ${errorText}`)
    }

    const tokenData = await tokenResponse.json()
    return tokenData.access_token
}

async function createJWTForGoogleCloud(credentials: any): Promise<string> {
    const header = { alg: 'RS256', typ: 'JWT', kid: credentials.private_key_id }
    const now = Math.floor(Date.now() / 1000)
    const payload = {
        iss: credentials.client_email,
        scope: 'https://www.googleapis.com/auth/cloud-platform',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600,
        iat: now,
    }

    const privateKeyPem = credentials.private_key.replace(/\\n/g, '\n')
    const privateKeyB64 = privateKeyPem
        .replace(/-----BEGIN PRIVATE KEY-----/, '')
        .replace(/-----END PRIVATE KEY-----/, '')
        .replace(/\s/g, '')

    const privateKeyBytes = Uint8Array.from(atob(privateKeyB64), c => c.charCodeAt(0))
    const privateKey = await crypto.subtle.importKey(
        'pkcs8', privateKeyBytes.buffer,
        { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
        false, ['sign']
    )

    const headerBase64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const payloadBase64 = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
    const signatureInput = `${headerBase64}.${payloadBase64}`

    const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(signatureInput))
    const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
        .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

    return `${signatureInput}.${signatureBase64}`
}

async function callVertexAI(request: ContentGenerationRequest, accessToken: string) {
    const prompt = `Generate an engaging daily health insight about nutrition for a wellness app user.

Topic: Nutrition and healthy eating
Target audience: Adults interested in preventive health
Tone: Conversational, encouraging, science-based
Requirements:
- Include one actionable tip
- Title must be under 60 characters
- Summary must be exactly 2 sentences under 200 characters

Format your response as:
Title: [Engaging headline under 60 characters]
Summary: [Exactly 2 sentences under 200 characters with actionable tip]`

    const url = `https://${VERTEX_AI_LOCATION}-aiplatform.googleapis.com/v1/projects/${GCP_PROJECT_ID}/locations/${VERTEX_AI_LOCATION}/publishers/google/models/text-bison@002:predict`

    const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            instances: [{ prompt }],
            parameters: { temperature: 0.7, maxOutputTokens: 300, topP: 0.8, topK: 40 }
        }),
    })

    if (!response.ok) {
        const errorText = await response.text()
        throw new Error(`Vertex AI API error: ${response.status} - ${errorText}`)
    }

    const data = await response.json()
    const prediction = data.predictions[0]
    const content = prediction.content || prediction.text || ''

    if (!content) return null

    // Parse response
    const titleMatch = content.match(/Title:\s*(.*?)(?:\n|$)/i)
    const summaryMatch = content.match(/Summary:\s*(.*?)(?:\n|$)/is)

    if (titleMatch && summaryMatch) {
        return {
            title: titleMatch[1].trim(),
            summary: summaryMatch[1].trim().replace(/\n/g, ' '),
            confidence_score: prediction.confidence || 0.85
        }
    }

    return null
}

// Run the test
if (import.meta.main) {
    await testVertexAI()
} 