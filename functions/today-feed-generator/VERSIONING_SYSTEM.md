# Content Versioning System

**Epic 1.3: Today Feed (AI Daily Brief)**  
**Task: T1.3.1.7 - Content Storage and Versioning System**  
**Status: ✅ Complete**

## Overview

The content versioning system provides comprehensive version control, change tracking, and delivery optimization for Today Feed content. This system enables content updates, rollbacks, audit trails, and CDN preparation.

## Database Schema

### Tables Created

#### 1. `content_versions`
Stores complete version history for all content changes.

```sql
- id: Serial primary key
- content_id: Reference to daily_feed_content
- version_number: Sequential version number per content
- title, summary, content_url, external_link: Content fields
- topic_category: Health topic
- ai_confidence_score: AI confidence level
- change_type: 'initial' | 'update' | 'rollback' | 'regeneration'
- change_reason: Why this version was created
- changed_by: User/system that made the change
- is_active: Only one version active per content
- created_at: Timestamp
```

#### 2. `content_change_log`
Audit trail for all content operations.

```sql
- id: Serial primary key
- content_id: Reference to daily_feed_content
- from_version: Previous version number
- to_version: New version number
- action_type: 'create' | 'update' | 'rollback' | 'publish' | 'unpublish'
- changed_by: User/system performing action
- change_notes: Description of changes
- old_values: JSONB of previous field values
- new_values: JSONB of new field values
- created_at: Timestamp
```

#### 3. `content_delivery_optimization`
CDN and caching optimization metadata.

```sql
- id: Serial primary key
- content_id: Reference to daily_feed_content (unique)
- etag: HTTP caching ETag
- last_modified: Last modification timestamp
- cache_control: HTTP cache control header
- compression_type: 'gzip' | 'br' | 'none'
- content_size: Size in bytes
- cdn_url: CDN URL if using external CDN
- cache_hits: Number of cache hits
- cache_misses: Number of cache misses
- updated_at: Last update timestamp
```

### Database Functions

#### `create_content_version()`
Creates new version when content changes.
- Automatically increments version number
- Deactivates previous versions
- Logs change in audit trail
- Updates delivery optimization

#### `rollback_content_version()`
Rolls back content to previous version.
- Validates target version exists
- Updates main content table
- Creates new version entry for rollback
- Maintains complete audit trail

#### `generate_content_etag()`
Generates SHA256-based ETag for HTTP caching.
- Based on content + version number
- Ensures cache invalidation on changes

#### `update_content_delivery_optimization()`
Updates caching and delivery metadata.
- Generates new ETag
- Calculates content size
- Updates optimization record

### Views

#### `content_with_versions`
Consolidated view combining content with version info.
- Current version number
- Last change information
- Delivery optimization data
- Total version count

### Triggers

#### `trigger_create_initial_version`
Automatically creates version 1 when new content is inserted.

#### `trigger_create_update_version`
Creates new version when content is updated (only if content actually changed).

## API Endpoints

### Version Management

#### `GET /versions/history?content_id={id}`
Get complete version history for content.

**Response:**
```json
{
  "success": true,
  "versions": [ContentVersion[]],
  "change_log": [ContentChangeLog[]],
  "total_versions": number,
  "current_version": number
}
```

#### `POST /versions/create`
Create new version manually.

**Request:**
```json
{
  "content_id": number,
  "change_type": "initial" | "update" | "rollback" | "regeneration",
  "change_reason": string,
  "changed_by": string
}
```

#### `POST /versions/rollback`
Rollback to previous version.

**Request:**
```json
{
  "content_id": number,
  "target_version": number,
  "rollback_reason": string,
  "changed_by": string
}
```

### Content Delivery

#### `GET /content/cached?date={YYYY-MM-DD}`
Get content with caching headers and optimization.

**Features:**
- HTTP ETag support
- If-None-Match handling
- If-Modified-Since support
- Cache hit/miss tracking
- Proper HTTP status codes (304 for cached)

#### `GET /delivery/stats?days={number}`
Get delivery and caching statistics.

**Response:**
```json
{
  "success": true,
  "period_days": number,
  "summary": {
    "total_requests": number,
    "cache_hits": number,
    "cache_misses": number,
    "hit_rate_percentage": string,
    "average_content_size_bytes": number
  },
  "content_stats": [DeliveryStats[]]
}
```

## TypeScript Types

### Core Types
- `ContentVersion`: Version record structure
- `ContentChangeLog`: Change log entry
- `ContentDeliveryOptimization`: Delivery optimization data
- `ContentWithVersions`: Extended content with version info

### Request/Response Types
- `CreateVersionRequest`: Version creation request
- `RollbackVersionRequest`: Rollback request
- `VersionManagementResponse`: Version operation response
- `VersionHistoryResponse`: Version history response
- `CachedContentResponse`: Cached content with headers

## Features Implemented

### ✅ Version Control
- Complete version history tracking
- Automatic version creation on content changes
- Manual version creation capability
- Version rollback functionality

### ✅ Change Tracking
- Comprehensive audit trail
- Before/after value tracking
- Change reason documentation
- User attribution

### ✅ Content Delivery Optimization
- HTTP ETag generation
- Cache control headers
- Content size tracking
- Cache hit/miss statistics

### ✅ CDN Preparation
- ETag-based cache invalidation
- Proper HTTP caching headers
- Content compression metadata
- CDN URL support

### ✅ Database Integrity
- Foreign key constraints
- Unique constraints on versions
- Row Level Security (RLS)
- Proper indexing for performance

## Usage Examples

### Creating a Version
```typescript
const response = await fetch('/versions/create', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    content_id: 123,
    change_type: 'update',
    change_reason: 'Fixed typo in summary',
    changed_by: 'admin@example.com'
  })
});
```

### Rolling Back Content
```typescript
const response = await fetch('/versions/rollback', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    content_id: 123,
    target_version: 2,
    rollback_reason: 'Reverting problematic changes',
    changed_by: 'admin@example.com'
  })
});
```

### Getting Cached Content
```typescript
const response = await fetch('/content/cached?date=2024-12-29', {
  headers: {
    'If-None-Match': 'cached-etag-value'
  }
});
// Returns 304 if content unchanged, 200 with content if changed
```

## Security & Permissions

### Row Level Security (RLS)
- All versioning tables have RLS enabled
- Content versions publicly readable
- Change log publicly readable (transparency)
- Delivery optimization publicly readable

### API Security
- Service role required for write operations
- Authenticated users can read version history
- Change attribution tracked for accountability

## Performance Considerations

### Indexing
- Optimized indexes on content_id, version_number
- Indexes on active versions and timestamps
- ETag indexing for fast cache lookups

### Caching Strategy
- 24-hour default cache control
- ETag-based cache invalidation
- Cache hit/miss tracking for optimization

### Storage Efficiency
- JSONB for flexible old/new value storage
- Compression metadata for CDN optimization
- Automatic cleanup of inactive versions (future enhancement)

## Next Steps

The versioning system is now ready for:
1. **T1.3.1.8**: Content moderation workflow integration
2. **T1.3.1.9**: CDN integration (CloudFlare/AWS CloudFront)
3. **T1.3.1.10**: Analytics and monitoring dashboard

## Migration

To apply the versioning system:

```bash
# Run the migration
python scripts/run_migration.py supabase/migrations/20241229000000_content_versioning_system.sql

# Verify tables created
# Check Supabase dashboard for new tables and functions
```

## Testing

The system includes comprehensive error handling and validation:
- Content ID validation
- Version number validation
- Change type validation
- Database constraint enforcement
- HTTP status code compliance

---

**Implementation Complete**: December 29, 2024  
**Next Task**: T1.3.1.8 - Content moderation and approval workflow 