# Today Feed Content Generator

A Google Cloud Run service that generates daily AI-powered health insights for the Bee MVP app's Today Feed feature.

## 🎯 Overview

This service is part of **Epic 1.3: Today Feed (AI Daily Brief)** and provides:

- **Daily Content Generation**: Automated creation of engaging health insights
- **AI-Powered Content**: Uses Vertex AI for intelligent content creation
- **Quality Validation**: Multi-factor content safety and quality checks
- **RESTful API**: Clean endpoints for content retrieval and management
- **Supabase Integration**: Direct database integration for content storage

## 🏗️ Architecture

```
Daily Schedule (3 AM UTC)
    ↓
Cloud Scheduler
    ↓
Today Feed Generator (Cloud Run)
    ↓
Vertex AI Content Generation
    ↓
Content Quality Validation
    ↓
Supabase Database Storage
    ↓
Mobile App API Consumption
```

## 📋 Features

- **Automated Content Generation**: Daily health insights generated at 3 AM UTC
- **Topic Rotation**: Intelligent selection across 6 health categories
- **Content Validation**: Safety checks for medical accuracy and appropriateness
- **Caching Support**: Optimized for mobile app content caching strategies
- **Health Monitoring**: Built-in health checks and monitoring endpoints
- **Error Handling**: Comprehensive error handling and logging

## 🚀 Quick Start

### Prerequisites

1. **Google Cloud Project** with the following APIs enabled:
   - Cloud Run API
   - Cloud Build API
   - AI Platform API (Vertex AI)

2. **Supabase Project** with the database schema deployed

3. **gcloud CLI** installed and authenticated

### Deployment

1. **Clone and navigate to the service directory**:
   ```bash
   cd functions/today-feed-generator
   ```

2. **Deploy to Cloud Run**:
   ```bash
   ./deploy.sh YOUR_PROJECT_ID us-central1
   ```

3. **Set up Supabase secrets** (see Configuration section below)

4. **Test the deployment**:
   ```bash
   curl https://your-service-url/health
   ```

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `SUPABASE_URL` | Your Supabase project URL | ✅ | - |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | ✅ | - |
| `GCP_PROJECT_ID` | Google Cloud project ID | ✅ | - |
| `VERTEX_AI_LOCATION` | Vertex AI service region | ❌ | `us-central1` |

### Setting up Secrets

Create Supabase configuration secrets in Google Secret Manager:

```bash
# Create the secret
gcloud secrets create supabase-config

# Add the Supabase URL
echo -n "https://your-project.supabase.co" | gcloud secrets versions add supabase-config --data-file=-

# Add the service role key
echo -n "your-service-role-key" | gcloud secrets versions add supabase-config --data-file=-
```

## 📡 API Endpoints

### Health Check
```http
GET /health
```
Returns service health status and version information.

**Response:**
```json
{
  "status": "healthy",
  "service": "today-feed-generator", 
  "timestamp": "2024-12-15T10:30:00Z",
  "version": "1.0.0"
}
```

### Generate Content
```http
POST /generate
```
Generates new content for a specific topic and date.

**Request Body:**
```json
{
  "topic": "nutrition",
  "date": "2024-12-15"
}
```

**Response:**
```json
{
  "success": true,
  "content": {
    "id": 123,
    "content_date": "2024-12-15",
    "title": "The Hidden Power of Colorful Eating",
    "summary": "Different colored fruits and vegetables contain unique antioxidants...",
    "topic_category": "nutrition",
    "ai_confidence_score": 0.85,
    "created_at": "2024-12-15T03:00:00Z"
  },
  "validation_result": {
    "is_valid": true,
    "confidence_score": 0.85,
    "safety_score": 0.95,
    "issues": []
  }
}
```

### Get Current Content
```http
GET /current
```
Retrieves today's published content.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "content_date": "2024-12-15",
    "title": "The Hidden Power of Colorful Eating",
    "summary": "Different colored fruits and vegetables contain unique antioxidants...",
    "topic_category": "nutrition",
    "ai_confidence_score": 0.85
  },
  "cached_at": "2024-12-15T10:30:00Z",
  "expires_at": "2024-12-16T10:30:00Z"
}
```

### Validate Content
```http
POST /validate
```
Validates content quality and safety.

**Request Body:**
```json
{
  "title": "Sample Health Title",
  "summary": "Sample health content summary...",
  "topic_category": "nutrition"
}
```

**Response:**
```json
{
  "is_valid": true,
  "confidence_score": 0.85,
  "safety_score": 0.95,
  "readability_score": 0.85,
  "engagement_score": 0.8,
  "issues": []
}
```

## 🔧 Content Topics

The service rotates through 6 health topic categories:

1. **Nutrition** - Food science, meal planning, healthy eating
2. **Exercise** - Movement benefits, workout tips, activity science  
3. **Sleep** - Sleep hygiene, recovery optimization, rest science
4. **Stress Management** - Mindfulness, relaxation, mental health
5. **Preventive Care** - Health screenings, early detection
6. **Lifestyle** - Habit formation, behavior change, wellness

## 🛡️ Content Safety

### Validation Checks

- **Length Limits**: Title ≤60 chars, Summary ≤200 chars
- **Medical Safety**: Prohibited terms screening (diagnose, prescription, cure, treatment)
- **Quality Thresholds**: AI confidence ≥0.7, Safety score ≥0.5
- **Readability**: 8th grade reading level maximum

### Content Guidelines

- ✅ Evidence-based health claims only
- ✅ Actionable tips and insights
- ✅ Encouraging and educational tone
- ❌ No medical diagnoses or prescription advice
- ❌ No fear-based messaging
- ❌ No unsubstantiated health claims

## 🧪 Testing

### Local Development

1. **Install Deno**:
   ```bash
   curl -fsSL https://deno.land/install.sh | sh
   ```

2. **Set environment variables**:
   ```bash
   export SUPABASE_URL="your-supabase-url"
   export SUPABASE_SERVICE_ROLE_KEY="your-service-key"
   export GCP_PROJECT_ID="your-project-id"
   ```

3. **Run the service**:
   ```bash
   deno run --allow-net --allow-env --allow-read index.ts
   ```

### Testing Endpoints

```bash
# Health check
curl http://localhost:8080/health

# Generate content
curl -X POST http://localhost:8080/generate \
  -H "Content-Type: application/json" \
  -d '{"topic": "nutrition", "date": "2024-12-15"}'

# Get current content
curl http://localhost:8080/current

# Validate content
curl -X POST http://localhost:8080/validate \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Title",
    "summary": "Test summary content.",
    "topic_category": "nutrition"
  }'
```

## 📊 Monitoring

### Health Checks

The service includes built-in health monitoring:

- **Liveness Probe**: `/health` endpoint every 10 seconds
- **Readiness Probe**: `/health` endpoint every 5 seconds
- **Startup Delay**: 30 seconds initial delay

### Logging

All requests and errors are logged with structured JSON for easy monitoring:

```json
{
  "level": "info",
  "timestamp": "2024-12-15T10:30:00Z",
  "message": "Content generated successfully",
  "topic": "nutrition",
  "date": "2024-12-15",
  "confidence_score": 0.85
}
```

## 🔄 Scheduling

For automated daily content generation, set up Cloud Scheduler:

```bash
# Create a scheduled job to run daily at 3 AM UTC
gcloud scheduler jobs create http daily-content-generation \
    --schedule="0 3 * * *" \
    --uri="https://your-service-url/generate" \
    --http-method=POST \
    --headers="Content-Type=application/json" \
    --message-body='{}' \
    --time-zone="UTC"
```

## 🚨 Troubleshooting

### Common Issues

1. **Service won't start**
   - Check environment variables are set correctly
   - Verify Supabase connectivity
   - Check GCP project permissions

2. **Content generation fails**
   - Verify Vertex AI API is enabled
   - Check service account permissions
   - Review content validation rules

3. **Database connection issues**
   - Verify Supabase URL and keys
   - Check RLS policies
   - Ensure database schema is deployed

### Debug Commands

```bash
# Check service logs
gcloud run services logs tail today-feed-generator --region=us-central1

# Test service locally
deno run --allow-net --allow-env --allow-read index.ts

# Validate deployment
gcloud run services describe today-feed-generator --region=us-central1
```

## 📚 Related Documentation

- [Epic 1.3 README](../../docs/5_epic_1_3/README.md)
- [Today Feed PRD](../../docs/5_epic_1_3/prd-today-feed.md)
- [Task Breakdown](../../docs/5_epic_1_3/tasks-today-feed.md)
- [Supabase Database Schema](../../supabase/migrations/)

## 🤝 Contributing

This service is part of the larger Bee MVP project. For contribution guidelines and development standards, see the main project README.

---

**Status**: ✅ T1.3.1.1 Complete - GCP Cloud Run service setup  
**Next**: T1.3.1.2 - Integrate Vertex AI for content generation pipeline  
**Epic**: 1.3 Today Feed (AI Daily Brief) 