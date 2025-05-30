# Today Feed Generator Service

**Epic 1.3: Today Feed (AI Daily Brief)**  
**Status**: ✅ Scheduled Content Generation Complete

## Overview

The Today Feed Generator is a Cloud Run service that automatically generates daily health content using Vertex AI. It runs on a scheduled basis at 3 AM UTC daily and provides AI-generated health insights across six topic categories.

## Features

### ✅ Completed Features

- **Automated Daily Generation**: Scheduled content generation at 3 AM UTC via Cloud Scheduler
- **Vertex AI Integration**: Uses Google's text-bison model for content generation
- **Intelligent Topic Selection**: Algorithm selects topics based on recency, engagement, and seasonal relevance
- **Content Quality Validation**: Comprehensive validation including readability, safety, and engagement scoring
- **Medical Safety Review**: Automated flagging and human review workflow for medical content
- **Idempotent Operations**: Prevents duplicate content generation for the same date
- **Retry Logic**: Exponential backoff retry with fallback content generation
- **Comprehensive Monitoring**: Health checks, error handling, and Cloud Monitoring integration

## Architecture

```
Cloud Scheduler (3 AM UTC) 
    ↓
Cloud Run Service (today-feed-generator)
    ↓
Vertex AI (text-bison@002) → Content Generation
    ↓
Quality Validation & Safety Review
    ↓
Supabase Database (daily_feed_content)
```

## API Endpoints

### Core Endpoints

- `GET /health` - Comprehensive health check with database connectivity
- `POST /generate` - Generate daily content (supports both manual and scheduled)
- `GET /current` - Get current day's content
- `POST /validate` - Validate content quality

### Review System Endpoints

- `GET /review/queue` - Get pending content reviews
- `POST /review/action` - Approve/reject/escalate content
- `GET /review/stats` - Review system statistics

## Scheduled Generation

### Cloud Scheduler Configuration

The service is automatically triggered daily at 3 AM UTC by Google Cloud Scheduler with the following configuration:

```json
{
  "scheduled": true,
  "source": "cloud-scheduler",
  "timezone": "UTC",
  "trigger_time": "3AM"
}
```

### Retry Policy

- **Retry Count**: 3 attempts
- **Max Retry Duration**: 10 minutes
- **Backoff**: Exponential (30s to 5 minutes)
- **Fallback**: Pre-written content if AI generation fails

### Idempotent Behavior

The service checks for existing content before generation:
- **Scheduled requests**: Skip generation if content exists (returns 200 with `skipped: true`)
- **Manual requests**: Allow regeneration even if content exists

## Content Generation Process

### 1. Topic Selection Algorithm

The intelligent topic selection considers:
- **Diversity**: Avoids recently used topics
- **User Engagement**: Prioritizes topics with higher engagement
- **Seasonal Relevance**: Adjusts for time of year (e.g., exercise in January)
- **Day of Week**: Considers weekly patterns (e.g., nutrition on Sundays)

### 2. AI Content Generation

- **Model**: Vertex AI text-bison@002
- **Temperature**: 0.7 (balanced creativity/consistency)
- **Max Tokens**: 300
- **Validation**: Comprehensive quality and safety checks

### 3. Quality Validation

Content is validated for:
- **Format**: Title ≤60 chars, Summary ≤200 chars
- **Readability**: Target 8th grade level
- **Engagement**: Actionable tips and compelling language
- **Safety**: Medical accuracy and appropriate disclaimers
- **Appropriateness**: Age-appropriate and educational

### 4. Review Workflow

- **Auto-approve**: High-quality content (safety score ≥0.95)
- **Human review**: Flagged content (safety score <0.8)
- **Escalation**: Complex medical topics

## Deployment

### Prerequisites

```bash
# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
```

### Deploy Service

```bash
# Deploy Cloud Run service
./deploy.sh

# Apply Terraform for Cloud Scheduler
cd ../../infra
terraform apply
```

### Configure Secrets

```bash
# Set Supabase secrets in Google Secret Manager
gcloud secrets versions add supabase-url --data="your-supabase-url"
gcloud secrets versions add supabase-service-key --data="your-service-key"
```

## Testing

### Manual Testing

```bash
# Test all endpoints
./test-scheduler.sh https://your-service-url

# Test specific endpoint
curl https://your-service-url/health
```

### Scheduled Testing

The scheduler can be tested by:
1. Triggering the Cloud Scheduler job manually
2. Checking logs for successful execution
3. Verifying content was generated in database

## Monitoring

### Health Checks

The `/health` endpoint provides comprehensive status:

```json
{
  "status": "healthy",
  "service": "today-feed-generator",
  "environment": {
    "gcp_project": "configured",
    "vertex_ai_location": "us-central1",
    "supabase_url": "configured",
    "google_credentials": "configured"
  },
  "database": {
    "connected": true,
    "last_check": "2024-12-28T10:00:00Z"
  },
  "scheduler": {
    "ready": true,
    "next_scheduled_run": "2024-12-29T03:00:00Z",
    "timezone": "UTC"
  }
}
```

### Cloud Monitoring

- **Alert Policy**: Triggers on Cloud Scheduler job failures
- **Metrics**: Job success/failure rates, execution duration
- **Logs**: Structured logging for debugging

### Key Metrics

- **Generation Success Rate**: >95% target
- **Content Quality Score**: >0.8 average
- **Review Queue Size**: <10 pending items
- **API Response Time**: <2 seconds

## Error Handling

### Retry Logic

1. **Vertex AI Failures**: 3 retries with exponential backoff
2. **Database Errors**: Immediate retry, then fallback
3. **Validation Failures**: Log and use fallback content

### Fallback Content

When AI generation fails, the service uses pre-written content:
- Topic-specific titles and summaries
- Lower confidence score (0.5)
- Automatically flagged for review

### Monitoring Alerts

- **Scheduler Failures**: Alert after 2+ consecutive failures
- **High Review Queue**: Alert when >20 items pending
- **Service Health**: Alert on unhealthy status

## Development

### Local Development

```bash
# Install Deno
curl -fsSL https://deno.land/install.sh | sh

# Run locally
deno run --allow-net --allow-env index.ts
```

### Environment Variables

```bash
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_ROLE_KEY=your-service-key
GCP_PROJECT_ID=your-project-id
VERTEX_AI_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=service-account-json
```

## Next Steps

### Upcoming Tasks (M1.3.1)

- **T1.3.1.7**: Content storage and versioning system
- **T1.3.1.8**: Content moderation and approval workflow  
- **T1.3.1.9**: Content delivery and CDN integration
- **T1.3.1.10**: Content analytics and monitoring system

### Future Enhancements

- A/B testing for content variations
- Personalized topic selection based on user preferences
- Multi-language content generation
- Advanced analytics and engagement tracking

## Support

For issues or questions:
1. Check service health: `curl https://your-service-url/health`
2. Review Cloud Run logs: `gcloud logs tail today-feed-generator`
3. Check Cloud Scheduler status in GCP Console
4. Verify Supabase connectivity and secrets

---

**Last Updated**: December 2024  
**Service Version**: 1.0.0  
**Epic**: 1.3 Today Feed (AI Daily Brief)  
**Task**: T1.3.1.6 ✅ Complete 