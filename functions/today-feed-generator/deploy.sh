#!/bin/bash

# Today Feed Content Generator - Cloud Run Deployment Script
# Usage: ./deploy.sh [PROJECT_ID] [REGION]

set -e

# Configuration
PROJECT_ID=${1:-"your-gcp-project-id"}
REGION=${2:-"us-central1"}
SERVICE_NAME="today-feed-generator"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🚀 Deploying Today Feed Content Generator to Cloud Run"
echo "Project: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service: ${SERVICE_NAME}"

# Ensure we're in the correct directory
cd "$(dirname "$0")"

# Check if gcloud is authenticated
echo "🔐 Checking gcloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "❌ Please authenticate with gcloud first: gcloud auth login"
    exit 1
fi

# Set the project
echo "🎯 Setting GCP project..."
gcloud config set project "${PROJECT_ID}"

# Enable required APIs
echo "🔧 Enabling required APIs..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable aiplatform.googleapis.com

# Build the container image
echo "🏗️  Building container image..."
gcloud builds submit --tag "${IMAGE_NAME}" .

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
    --image="${IMAGE_NAME}" \
    --platform=managed \
    --region="${REGION}" \
    --allow-unauthenticated \
    --memory=1Gi \
    --cpu=1 \
    --max-instances=10 \
    --min-instances=0 \
    --port=8080 \
    --timeout=300 \
    --concurrency=100 \
    --set-env-vars="GCP_PROJECT_ID=${PROJECT_ID},VERTEX_AI_LOCATION=${REGION}"

# Get the service URL
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" --region="${REGION}" --format="value(status.url)")

echo "✅ Deployment complete!"
echo "📍 Service URL: ${SERVICE_URL}"
echo "🏥 Health check: ${SERVICE_URL}/health"
echo ""
echo "🔧 Next steps:"
echo "1. Set up Supabase secrets (see README.md)"
echo "2. Configure Cloud Scheduler for daily content generation"
echo "3. Test the service endpoints"
echo ""
echo "🧪 Test the service:"
echo "curl ${SERVICE_URL}/health" 