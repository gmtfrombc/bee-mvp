# Product Requirements Document: On-Demand Lesson Library

**Epic:** 1.2 · Core Mobile Experience  
**Feature:** On-Demand Lesson Library  
**Version:** 1.0  
**Status:** 📝 Draft  
**Created:** December 2024  
**Owner:** Product Team  

---

## 📋 Executive Summary

The On-Demand Lesson Library provides users with easy access to structured educational content (FAQs, lesson PDFs, NotebookLM podcasts) hosted on WordPress. It serves as a key learning component in the BEE platform, offering searchable, filterable, and offline-accessible educational resources that support users' health journey while integrating with the momentum meter to reward learning engagement.

### **Key Benefits**
- **Accessible Learning:** Offline-capable content library for flexible access
- **Personalized Discovery:** Tag-based search and filtering for relevant content
- **Progress Tracking:** Completion badges and momentum integration
- **Seamless Integration:** WordPress CMS integration for easy content management
- **Engagement Rewards:** Learning activities boost user momentum scores

---

## 🎯 Problem Statement

Users need easy access to educational health content to support their behavior change journey, but current solutions often require internet connectivity, lack proper organization, or don't provide feedback on learning progress. Users struggle to find relevant content quickly and lack motivation to engage with educational materials consistently.

### **User Pain Points**
- Difficulty finding relevant educational content
- No offline access to learning materials
- Lack of progress tracking for completed lessons
- No integration between learning activities and overall engagement
- Poor search and discovery experience
- Content scattered across multiple platforms

---

## 🎯 Product Goals

### **Primary Goals**
1. **Increase User Education:** Provide accessible, high-quality health education content
2. **Improve Content Discovery:** Enable efficient search and filtering of lessons
3. **Support Offline Learning:** Ensure content availability without internet connection
4. **Track Learning Progress:** Monitor completion rates and reward engagement
5. **Boost User Momentum:** Integrate lesson completion with momentum scoring

### **Success Metrics**
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Lesson completion rate | 60% | Analytics tracking |
| Daily lesson library engagement | 40% | App analytics |
| Offline content access rate | 80% | Cache usage metrics |
| Search success rate | 85% | Search result interactions |
| Time to find relevant content | <30 seconds | User journey analytics |
| Content caching efficiency | 95% | Cache hit rate |

---

## 👥 User Stories

### **Epic User Story**
> As a health program participant, I want to access educational content easily and track my learning progress so that I can improve my health knowledge and stay motivated in my health journey.

### **Detailed User Stories**

#### **US1.2.1: Browse Lesson Library**
**As a** program participant  
**I want to** view available lessons in an organized list  
**So that** I can discover educational content relevant to my health goals  

**Acceptance Criteria:**
- [ ] Lesson list displays with card layout showing title, image, and completion status
- [ ] Content loads within 3 seconds from cache or network
- [ ] Lessons are organized by categories (nutrition, activity, mindset)
- [ ] Completion badges are clearly visible on completed lessons

#### **US1.2.2: Search and Filter Content**
**As a** program participant  
**I want to** search for specific topics or filter by tags  
**So that** I can quickly find relevant educational content  

**Acceptance Criteria:**
- [ ] Search functionality finds lessons by title, content, and tags
- [ ] Filter options include nutrition, activity, mindset, and other relevant tags
- [ ] Search results display within 2 seconds
- [ ] Clear filter state and reset options available

#### **US1.2.3: Access Content Offline**
**As a** program participant  
**I want to** access previously downloaded lessons without internet  
**So that** I can continue learning regardless of connectivity  

**Acceptance Criteria:**
- [ ] Previously viewed lessons cached automatically
- [ ] Offline indicator shows available content
- [ ] Cached content displays without network dependency
- [ ] Manual download option for future offline access

#### **US1.2.4: Track Learning Progress**
**As a** program participant  
**I want to** see my learning progress and completion status  
**So that** I can track my educational achievements and stay motivated  

**Acceptance Criteria:**
- [ ] Completion badges display on finished lessons
- [ ] Progress percentage shown for partially completed content
- [ ] Learning achievements contribute to momentum meter
- [ ] Learning history accessible in user profile

#### **US1.2.5: Consume Educational Content**
**As a** program participant  
**I want to** read, watch, or listen to educational content  
**So that** I can learn about health topics relevant to my journey  

**Acceptance Criteria:**
- [ ] In-app WebView displays WordPress content smoothly
- [ ] PDF content renders correctly within the app
- [ ] Audio content (podcasts) plays with standard media controls
- [ ] Content completion tracked automatically (90% threshold)

---

## 🏗️ Technical Requirements

### **System Architecture**

#### **Backend Components**
1. **WordPress Integration Service**
   - REST API connection to WordPress CMS
   - Content synchronization and caching
   - Media asset management
   - Content metadata extraction

2. **Content Management System**
   - Lesson data synchronization
   - Tag and category management
   - Content versioning support
   - Media optimization and delivery

3. **Progress Tracking Service**
   - Completion status monitoring
   - Progress percentage calculation
   - Momentum integration points
   - Learning analytics collection

#### **Frontend Components**
1. **Flutter Lesson Library Widget**
   - Card-based lesson layout
   - Search and filter interface
   - Offline content indicators
   - Progress visualization

2. **Content Viewer Components**
   - In-app WebView for WordPress content
   - PDF reader integration
   - Audio player for podcast content
   - Progress tracking overlay

3. **Offline Storage System**
   - SQLite database for lesson metadata
   - Local file storage for content
   - Cache management and cleanup
   - Sync status tracking

### **Database Schema**

#### **New Tables**
```sql
-- Lesson content metadata
CREATE TABLE lessons (
    id UUID PRIMARY KEY,
    wordpress_id INTEGER UNIQUE NOT NULL,
    title TEXT NOT NULL,
    slug TEXT NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('article', 'pdf', 'podcast', 'video')),
    description TEXT,
    featured_image_url TEXT,
    content_url TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    categories TEXT[] DEFAULT '{}',
    estimated_duration_minutes INTEGER,
    difficulty_level TEXT CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    published_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW(),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    cached_content TEXT,
    content_hash TEXT
);

-- User lesson progress tracking
CREATE TABLE user_lesson_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    lesson_id UUID NOT NULL,
    progress_percentage NUMERIC(5,2) DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    completed_at TIMESTAMP,
    last_accessed_at TIMESTAMP DEFAULT NOW(),
    time_spent_seconds INTEGER DEFAULT 0,
    is_bookmarked BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, lesson_id)
);

-- Lesson content cache
CREATE TABLE lesson_cache (
    lesson_id UUID PRIMARY KEY,
    content_data BYTEA,
    media_files JSONB DEFAULT '{}',
    cached_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    file_size_bytes BIGINT
);

-- User search history
CREATE TABLE lesson_search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    search_query TEXT NOT NULL,
    results_count INTEGER DEFAULT 0,
    clicked_lesson_id UUID,
    searched_at TIMESTAMP DEFAULT NOW()
);
```

#### **Existing Table Updates**
```sql
-- Add lesson-related engagement events
ALTER TABLE engagement_events 
ADD COLUMN lesson_id UUID,
ADD COLUMN content_type TEXT,
ADD COLUMN progress_percentage NUMERIC(5,2);

-- Index for performance
CREATE INDEX idx_engagement_events_lessons 
ON engagement_events (user_id, event_type, lesson_id, recorded_at);

CREATE INDEX idx_lessons_search 
ON lessons USING gin(to_tsvector('english', title || ' ' || description));

CREATE INDEX idx_lessons_tags 
ON lessons USING gin(tags);

CREATE INDEX idx_user_lesson_progress_user 
ON user_lesson_progress (user_id, last_accessed_at DESC);
```

### **API Specifications**

#### **GET /v1/lessons**
Returns paginated list of available lessons with filtering options.

**Parameters:**
- `page` (integer): Page number for pagination
- `limit` (integer): Number of items per page (max 50)
- `category` (string): Filter by category
- `tags` (array): Filter by tags
- `search` (string): Search query
- `difficulty` (string): Filter by difficulty level

**Response:**
```json
{
  "lessons": [
    {
      "id": "uuid",
      "title": "Understanding Nutrition Labels",
      "description": "Learn how to read and interpret nutrition labels effectively",
      "content_type": "article",
      "featured_image_url": "https://example.com/image.jpg",
      "tags": ["nutrition", "basics"],
      "categories": ["nutrition"],
      "estimated_duration_minutes": 15,
      "difficulty_level": "beginner",
      "is_featured": true,
      "published_at": "2024-12-01T10:00:00Z",
      "user_progress": {
        "progress_percentage": 0,
        "is_completed": false,
        "is_bookmarked": false,
        "last_accessed_at": null
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_items": 45,
    "total_pages": 3,
    "has_next": true,
    "has_previous": false
  }
}
```

#### **GET /v1/lessons/{lesson_id}**
Returns detailed lesson content and user progress.

**Response:**
```json
{
  "id": "uuid",
  "title": "Understanding Nutrition Labels",
  "content_url": "https://cms.example.com/lessons/nutrition-labels",
  "content_type": "article",
  "cached_content": "HTML content for offline viewing",
  "media_files": {
    "images": ["url1", "url2"],
    "videos": ["url3"],
    "audio": []
  },
  "user_progress": {
    "progress_percentage": 45.5,
    "time_spent_seconds": 678,
    "last_accessed_at": "2024-12-15T14:30:00Z",
    "is_completed": false,
    "is_bookmarked": true
  }
}
```

#### **POST /v1/lessons/{lesson_id}/progress**
Updates user progress for a specific lesson.

**Request:**
```json
{
  "progress_percentage": 75.5,
  "time_spent_seconds": 450,
  "action": "view" // "view", "complete", "bookmark", "unbookmark"
}
```

**Response:**
```json
{
  "success": true,
  "momentum_bonus": 2,
  "achievement_unlocked": false,
  "updated_progress": {
    "progress_percentage": 75.5,
    "is_completed": false,
    "total_time_spent": 1128
  }
}
```

---

## 🎨 User Experience Requirements

### **Lesson Library Interface Design**

#### **Main Library View**
- **Layout:** Grid of lesson cards (2 columns on mobile, 3+ on tablet)
- **Card Elements:** Featured image, title, duration, difficulty, completion badge
- **Interaction:** Tap to open, long-press for options (bookmark, download)
- **Search Bar:** Prominent search with filter icon
- **Categories:** Horizontal scrollable category chips

#### **Search and Filter Interface**
- **Search Input:** Real-time search with suggestions
- **Filter Panel:** Slide-up panel with category, tag, and difficulty filters
- **Results View:** Same card layout with result count
- **Clear Filters:** Easy reset to browse all content

#### **Content Viewer Interface**
- **WebView Integration:** Full-screen WordPress content display
- **Progress Indicator:** Bottom progress bar showing reading completion
- **Navigation:** Back button, bookmark toggle, share option
- **Offline Mode:** Clear indicator when viewing cached content

### **Interaction Patterns**

#### **Primary Interactions**
1. **Browse Library:** Scroll through lesson cards with pull-to-refresh
2. **Search Content:** Type query with real-time filtering
3. **View Lesson:** Tap card to open content in viewer
4. **Track Progress:** Automatic progress tracking with visual feedback
5. **Bookmark Content:** Heart icon for saving favorite lessons

#### **Accessibility Requirements**
- **Screen Reader:** Full VoiceOver/TalkBack support with content descriptions
- **Color Contrast:** WCAG AA compliance for all text and UI elements
- **Touch Targets:** 44px minimum for all interactive elements
- **Dynamic Type:** Support for iOS/Android text scaling
- **Reduced Motion:** Respect system motion preferences

---

## 🔧 Content Synchronization & Caching

### **WordPress Integration Logic**
```python
def sync_lessons_from_wordpress():
    """
    Synchronize lesson content from WordPress CMS
    with intelligent caching and conflict resolution.
    """
    
    # Fetch lessons from WordPress REST API
    wp_api_url = "https://cms.example.com/wp-json/wp/v2/posts"
    params = {
        "categories": "lessons",
        "per_page": 100,
        "orderby": "modified",
        "order": "desc"
    }
    
    lessons = fetch_wordpress_content(wp_api_url, params)
    
    for lesson in lessons:
        # Check if content has changed
        content_hash = generate_content_hash(lesson)
        existing_lesson = get_lesson_by_wordpress_id(lesson["id"])
        
        if not existing_lesson or existing_lesson.content_hash != content_hash:
            # Update or create lesson
            lesson_data = {
                "wordpress_id": lesson["id"],
                "title": lesson["title"]["rendered"],
                "content_url": lesson["link"],
                "tags": extract_tags(lesson),
                "categories": extract_categories(lesson),
                "featured_image_url": get_featured_image(lesson),
                "content_hash": content_hash
            }
            
            upsert_lesson(lesson_data)
            
            # Cache content for offline access
            cache_lesson_content(lesson["id"], lesson["content"]["rendered"])

def cache_lesson_content(lesson_id, content):
    """Cache lesson content and associated media for offline access."""
    
    # Extract and download media files
    media_urls = extract_media_urls(content)
    cached_media = {}
    
    for media_url in media_urls:
        local_path = download_and_store_media(media_url)
        cached_media[media_url] = local_path
    
    # Store in lesson_cache table
    cache_data = {
        "lesson_id": lesson_id,
        "content_data": compress_content(content),
        "media_files": cached_media,
        "expires_at": datetime.now() + timedelta(days=30)
    }
    
    store_lesson_cache(cache_data)
```

### **Progress Tracking Algorithm**
```python
def track_lesson_progress(user_id, lesson_id, scroll_percentage, time_spent):
    """
    Track user progress through lesson content
    with completion detection and momentum integration.
    """
    
    # Update progress in database
    progress_data = {
        "user_id": user_id,
        "lesson_id": lesson_id,
        "progress_percentage": max(scroll_percentage, get_current_progress(user_id, lesson_id)),
        "time_spent_seconds": time_spent,
        "last_accessed_at": datetime.now()
    }
    
    update_lesson_progress(progress_data)
    
    # Check for completion (90% threshold)
    if scroll_percentage >= 90 and not is_lesson_completed(user_id, lesson_id):
        mark_lesson_completed(user_id, lesson_id)
        
        # Trigger momentum bonus
        momentum_bonus = calculate_lesson_momentum_bonus(lesson_id)
        add_engagement_event(user_id, "lesson_complete", momentum_bonus)
        
        # Check for learning achievements
        check_learning_achievements(user_id)
        
        return {"completed": True, "momentum_bonus": momentum_bonus}
    
    return {"completed": False, "momentum_bonus": 0}

def calculate_lesson_momentum_bonus(lesson_id):
    """Calculate momentum bonus based on lesson characteristics."""
    lesson = get_lesson(lesson_id)
    
    base_bonus = 2.0
    
    # Difficulty multiplier
    difficulty_multiplier = {
        "beginner": 1.0,
        "intermediate": 1.2,
        "advanced": 1.5
    }
    
    # Duration bonus for longer content
    duration_bonus = min(lesson.estimated_duration_minutes / 30, 0.5)
    
    return base_bonus * difficulty_multiplier.get(lesson.difficulty_level, 1.0) + duration_bonus
```

---

## 🔗 Integration Requirements

### **Epic 2.1: Engagement Events Logging**
- **Dependency:** Complete ✅
- **Integration:** Lesson progress events logged to `engagement_events` table
- **Data Flow:** Content interactions → Event logging → Momentum calculation

### **Epic 1.1: Momentum Meter**
- **Dependency:** Complete ✅
- **Integration:** Lesson completion boosts momentum scores
- **Weight:** +2-3 points per lesson completed (based on difficulty)
- **Feedback:** Immediate momentum update on completion

### **Future Epic Integrations**

#### **Epic 1.3: Today Feed**
- **Integration Point:** Featured lessons in daily content
- **Weight:** Promoted lessons based on user interests
- **Feedback:** Today feed can promote relevant lessons

#### **Epic 1.4: In-App Messaging**
- **Integration Point:** Coaches can recommend specific lessons
- **Features:** Direct lesson links in coach messages
- **Analytics:** Track coach-recommended lesson engagement

### **WordPress CMS Integration**
- **Content Management:** WordPress admin panel for lesson creation
- **API Access:** REST API for content synchronization
- **Media Handling:** WordPress media library integration
- **SEO Features:** WordPress SEO plugins supported

---

## 📊 Analytics & Monitoring

### **Key Performance Indicators**

#### **Content Engagement Metrics**
- Lesson completion rates by category and difficulty
- Time spent per lesson and session duration
- Search query success rates and popular terms
- Bookmark and favorite lesson patterns
- Offline content usage statistics

#### **Learning Effectiveness Metrics**
- Progress completion percentages
- Learning streaks and consistency patterns
- Content preference analysis
- User pathway through lesson sequences
- Knowledge retention indicators (future surveys)

#### **Technical Performance Metrics**
- Content synchronization success rates
- Cache hit rates and offline performance
- Search response times and accuracy
- Content loading speeds and errors
- WordPress API response times

### **A/B Testing Framework**
- **Content Layouts:** Test different card designs and information hierarchy
- **Search Interface:** Optimize search and filter user experience
- **Progress Indicators:** Test different completion visualization methods
- **Recommendation Engine:** Test algorithm for suggesting relevant content

---

## 🚀 Launch Strategy

### **Phase 1: Core Library (Week 1-2)**
- Basic lesson listing with WordPress integration
- Simple search and category filtering
- WebView content display
- Basic progress tracking

### **Phase 2: Enhanced Features (Week 3-4)**
- Offline content caching
- Advanced search with full-text indexing
- Completion badges and momentum integration
- User bookmarking and favorites

### **Phase 3: Optimization (Week 5+)**
- Performance optimization and caching improvements
- Enhanced analytics and user insights
- Content recommendation engine
- Advanced accessibility features

---

## ⚠️ Risks & Mitigation

### **Technical Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| WordPress API changes | High | Medium | Version-specific API integration with fallbacks |
| Large content caching issues | Medium | Medium | Progressive caching and storage limits |
| Search performance degradation | Medium | Low | Optimized indexing and caching strategies |
| Offline synchronization conflicts | Medium | Low | Conflict resolution algorithms |

### **User Experience Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Content discovery difficulties | High | Medium | Improved search UX and categorization |
| Slow content loading | Medium | Medium | Aggressive caching and optimization |
| Completion tracking inaccuracy | Medium | Low | Multiple progress detection methods |

### **Business Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| WordPress hosting dependency | High | Low | Backup content delivery mechanisms |
| Content quality control | Medium | Medium | Editorial review process |
| User engagement plateau | Medium | Medium | Regular content updates and gamification |

---

## 📋 Acceptance Criteria

### **Epic-Level Acceptance Criteria**
- [ ] Lesson library loads within 3 seconds with full content list
- [ ] Search finds relevant lessons in under 2 seconds
- [ ] 90% of lessons cached successfully for offline access
- [ ] Completion tracking accuracy ≥95% for content scrolling
- [ ] WordPress content displays correctly in WebView
- [ ] Progress badges and momentum integration work seamlessly
- [ ] Filter functionality works correctly for all categories and tags
- [ ] Offline mode indicator and functionality work reliably
- [ ] Accessibility requirements met (WCAG AA compliance)
- [ ] Performance targets achieved (load time, search speed, caching)

### **Quality Assurance Requirements**
- [ ] Unit tests for content synchronization and progress tracking
- [ ] Integration tests for WordPress API and caching systems
- [ ] UI tests for lesson library and content viewer interactions
- [ ] Performance tests for content loading and search functionality
- [ ] Accessibility tests with screen readers and voice navigation
- [ ] Cross-device compatibility testing (iPhone SE to iPad Pro)
- [ ] Offline functionality testing in various network conditions

---

## 📚 Appendices

### **Appendix A: Content Strategy**
- WordPress content structure and taxonomy
- Lesson creation guidelines and templates
- Content quality standards and review process
- Media optimization and accessibility requirements

### **Appendix B: Technical Specifications**
- Detailed API documentation and response schemas
- Database migration scripts and indexing strategies
- Caching implementation and storage management
- Search indexing and query optimization

### **Appendix C: Design Assets**
- Figma mockups for lesson library interface
- Icon and badge design specifications
- Typography and spacing guidelines for content display
- Animation specifications for interactions and loading states

---

**Document Status:** 📝 Draft  
**Next Review:** Design Team and Content Team Approval  
**Approval Required:** Product Team, Engineering Team, Content Team  
**Target Start Date:** Week 1, Epic 1.2  

---

*This PRD serves as the definitive specification for the On-Demand Lesson Library feature. All implementation decisions should reference this document, and any changes must be approved through the standard change management process.* 