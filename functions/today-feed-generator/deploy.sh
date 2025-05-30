#!/bin/bash

# Today Feed Generator Deployment Script
# Epic 1.3: Today Feed (AI Daily Brief)

set -e

echo "🚀 Deploying Today Feed Generator Service..."

# Check if required environment variables are set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ Error: GCP_PROJECT_ID environment variable is not set"
    exit 1
fi

if [ -z "$GCP_REGION" ]; then
    echo "❌ Error: GCP_REGION environment variable is not set"
    exit 1
fi

# Build and deploy the Cloud Run service
echo "📦 Building Docker image..."
gcloud builds submit --tag gcr.io/$GCP_PROJECT_ID/today-feed-generator:latest .

echo "🚀 Deploying to Cloud Run..."
gcloud run deploy today-feed-generator \
    --image gcr.io/$GCP_PROJECT_ID/today-feed-generator:latest \
    --platform managed \
    --region $GCP_REGION \
    --allow-unauthenticated \
    --memory 1Gi \
    --cpu 1 \
    --timeout 300 \
    --concurrency 100 \
    --max-instances 10 \
    --min-instances 0

# Get the service URL
SERVICE_URL=$(gcloud run services describe today-feed-generator --region=$GCP_REGION --format="value(status.url)")

echo "✅ Service deployed successfully!"
echo "🔗 Service URL: $SERVICE_URL"

# Test the health endpoint
echo "🔍 Testing health endpoint..."
curl -s "$SERVICE_URL/health" | jq '.'

# Test manual content generation
echo "🧪 Testing manual content generation..."
curl -s -X POST "$SERVICE_URL/generate" \
    -H "Content-Type: application/json" \
    -d '{"scheduled": false, "source": "manual-test"}' | jq '.'

echo "✅ Deployment and testing complete!"
echo ""
echo "📋 Next steps:"
echo "1. Apply Terraform configuration to set up Cloud Scheduler"
echo "2. Configure Supabase secrets in Google Secret Manager"
echo "3. Test scheduled generation at 3 AM UTC"
echo ""
echo "🔧 Useful commands:"
echo "  Health check: curl $SERVICE_URL/health"
echo "  Manual generation: curl -X POST $SERVICE_URL/generate -H 'Content-Type: application/json' -d '{}'"
echo "  View logs: gcloud logs tail today-feed-generator --region=$GCP_REGION" 