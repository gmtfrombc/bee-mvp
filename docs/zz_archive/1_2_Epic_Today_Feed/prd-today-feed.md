# Product Requirements Document: Today Feed (AI Daily Brief)

**Epic:** 1.3 · Core Mobile Experience  
**Feature:** Today Feed (AI Daily Brief)  
**Version:** 1.0  
**Status:** 📝 Draft  
**Created:** December 2024  
**Owner:** Product Team  

---

## 📋 Executive Summary

The Today Feed is a daily AI-generated health brief that delivers a single, engaging health topic each day to spark curiosity and conversation. It replaces overwhelming information feeds with curated, bite-sized content designed to educate and motivate users while boosting their momentum meter engagement.

### **Key Benefits**
- **Educational:** Provides daily health insights without information overload
- **Engaging:** Single-focus content that's easy to consume and act upon
- **Momentum-Driven:** Integrates with momentum meter for engagement tracking
- **Curiosity-Focused:** Sparks interest in health topics for deeper exploration

---

## 🎯 Problem Statement

Users in health programs often feel overwhelmed by too much health information or don't know where to start with health education. Traditional health content feeds are either too generic, too medical, or too lengthy for busy users to engage with consistently.

### **User Pain Points**
- Information overload from multiple health content sources
- Generic content that doesn't feel relevant or interesting
- Difficulty knowing what health topics to focus on daily
- Lack of digestible, actionable health information
- Poor consistency in health education engagement

---

## 🎯 Product Goals

### **Primary Goals**
1. **Increase Daily Engagement:** Provide compelling reason to open app daily
2. **Support Health Education:** Deliver consistent, quality health information
3. **Boost Momentum Scores:** +1 momentum points for daily engagement
4. **Reduce Information Overload:** Single, focused content piece per day
5. **Foster Curiosity:** Encourage deeper exploration of health topics

### **Success Metrics**
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Daily Today Feed engagement rate | 60% | App analytics |
| Average time spent reading content | 2+ minutes | User interaction tracking |
| Click-through rate to external links | 25% | Link analytics |
| User satisfaction with content relevance | 80% | In-app feedback |
| Contribution to daily momentum score | +1 point per engagement | Momentum algorithm |

---

## 👥 User Stories

### **Epic User Story**
> As a health program participant, I want to receive daily health insights that are interesting and relevant so that I can learn something new each day without feeling overwhelmed by too much information.

### **Detailed User Stories**

#### **US1.3.1: View Daily Health Brief**
**As a** program participant  
**I want to** see today's health topic when I open the app  
**So that** I can learn something new and interesting about health  

**Acceptance Criteria:**
- [ ] Today Feed tile is prominently displayed on main screen
- [ ] Content includes engaging title and 2-sentence summary
- [ ] Content refreshes automatically at local midnight
- [ ] Visual design is inviting and easy to scan

#### **US1.3.2: Explore Content Details**
**As a** program participant  
**I want to** read more about today's health topic  
**So that** I can gain deeper understanding of the subject  

**Acceptance Criteria:**
- [ ] "Read more" link opens additional content seamlessly
- [ ] External links open in appropriate browser/app
- [ ] Content loads quickly and is mobile-optimized
- [ ] Easy navigation back to app main screen

#### **US1.3.3: Access Content Offline**
**As a** program participant  
**I want to** access today's content even when offline  
**So that** I can read it regardless of my connectivity  

**Acceptance Criteria:**
- [ ] Today's content is cached for offline access
- [ ] Previous day's content available as fallback
- [ ] Clear indication when viewing cached vs. live content
- [ ] Graceful handling of network connectivity issues

#### **US1.3.4: Engage and Earn Momentum**
**As a** program participant  
**I want to** be recognized for engaging with daily content  
**So that** my learning efforts contribute to my overall progress  

**Acceptance Criteria:**
- [ ] First daily engagement awards +1 momentum point
- [ ] Momentum update happens immediately upon interaction
- [ ] Visual feedback confirms momentum point award
- [ ] No duplicate points for multiple views same day

---

## 🏗️ Technical Requirements

### **System Architecture**

#### **Backend Components**
1. **Content Pipeline (GCP)**
   - Cloud Run service for AI content generation
   - Scheduled daily content creation (triggered at 3 AM UTC)
   - Content moderation and quality assurance
   - Integration with Vertex AI for content generation

2. **Content Storage**
   - Cloud Storage for content assets and media
   - Supabase for content metadata and analytics
   - CDN for fast global content delivery
   - Backup storage for content versioning

3. **API Services**
   - RESTful API endpoints for content retrieval
   - Real-time content update notifications
   - Analytics tracking for content engagement
   - A/B testing framework for content optimization

#### **Frontend Components**
1. **Flutter Today Feed Widget**
   - Material Design 3 card component
   - Responsive design for all screen sizes
   - Smooth loading states and animations
   - Accessibility compliance

2. **Content Display**
   - Rich text rendering for summaries
   - In-app browser for external content
   - Share functionality for social media
   - Bookmark feature for favorite topics

3. **Caching System**
   - Local storage for offline content access
   - 24-hour refresh cycle management
   - Background sync when connectivity restored
   - Cache size management and cleanup

### **Database Schema**

#### **New Tables**
```sql
-- Daily content feed
CREATE TABLE daily_feed_content (
    id SERIAL PRIMARY KEY,
    content_date DATE NOT NULL UNIQUE,
    title TEXT NOT NULL,
    summary TEXT NOT NULL,
    content_url TEXT,
    external_link TEXT,
    topic_category TEXT NOT NULL,
    ai_confidence_score NUMERIC(3,2),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User content interactions
CREATE TABLE user_content_interactions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    content_id INTEGER NOT NULL REFERENCES daily_feed_content(id),
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'click', 'share', 'bookmark')),
    interaction_timestamp TIMESTAMP DEFAULT NOW(),
    session_duration INTEGER, -- seconds spent reading
    UNIQUE(user_id, content_id, interaction_type)
);

-- Content analytics
CREATE TABLE content_analytics (
    id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES daily_feed_content(id),
    total_views INTEGER DEFAULT 0,
    total_clicks INTEGER DEFAULT 0,
    total_shares INTEGER DEFAULT 0,
    total_bookmarks INTEGER DEFAULT 0,
    avg_session_duration NUMERIC(5,2),
    engagement_rate NUMERIC(3,2),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### **Row Level Security (RLS)**
```sql
-- Enable RLS on user interactions
ALTER TABLE user_content_interactions ENABLE ROW LEVEL SECURITY;

-- Users can only see their own interactions
CREATE POLICY "Users can view own content interactions" ON user_content_interactions
    FOR ALL USING (auth.uid() = user_id);

-- Content is publicly readable
ALTER TABLE daily_feed_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Content is publicly readable" ON daily_feed_content
    FOR SELECT USING (true);
```

### **API Specifications**

#### **GET /v1/today-feed/current**
Returns today's featured content.

**Response:**
```json
{
  "content_id": 12345,
  "content_date": "2024-12-15",
  "title": "The Hidden Connection Between Sleep and Immune Function",
  "summary": "New research reveals that just one night of poor sleep can reduce your immune system's effectiveness by up to 70%. Here's what you need to know about optimizing your sleep for better health.",
  "content_url": "https://content.bee-app.com/sleep-immune-connection",
  "external_link": "https://example.com/sleep-research-study",
  "topic_category": "sleep",
  "engagement_stats": {
    "total_views": 1247,
    "avg_reading_time": 180,
    "user_rating": 4.3
  },
  "user_interaction": {
    "has_viewed": false,
    "has_clicked": false,
    "bookmarked": false,
    "momentum_earned": false
  },
  "cached_at": "2024-12-15T06:00:00Z",
  "expires_at": "2024-12-16T06:00:00Z"
}
```

#### **POST /v1/today-feed/interact**
Logs user interaction with content.

**Request:**
```json
{
  "content_id": 12345,
  "interaction_type": "view",
  "session_duration": 120,
  "timestamp": "2024-12-15T10:30:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "momentum_awarded": true,
  "momentum_points": 1,
  "message": "Great job staying curious about your health! +1 momentum"
}
```

#### **GET /v1/today-feed/history**
Returns recent content history for fallback scenarios.

**Response:**
```json
{
  "content_history": [
    {
      "content_date": "2024-12-14",
      "title": "5 Simple Ways to Boost Your Energy Naturally",
      "summary": "Skip the afternoon coffee crash with these science-backed energy boosters...",
      "cached": true
    },
    {
      "content_date": "2024-12-13", 
      "title": "Why Laughter Really Is the Best Medicine",
      "summary": "Studies show that laughter can boost immune function and reduce stress hormones...",
      "cached": true
    }
  ]
}
```

---

## 🎨 User Experience Requirements

### **Today Feed Tile Design**

#### **Visual Components**
- **Header:** "Today's Health Insight" with date
- **Title:** Engaging, curiosity-driving headline (max 60 characters)
- **Summary:** 2-sentence preview (max 200 characters)
- **Visual:** AI-generated or curated image related to topic
- **CTA Button:** "Read More" or "Learn More"
- **Engagement Indicator:** Shows if momentum point earned

#### **Interaction States**
1. **Fresh Content:** New content available, unread indicator
2. **Engaged:** User has viewed content, momentum point earned
3. **Loading:** Content refreshing, skeleton animation
4. **Offline:** Cached content displayed with offline indicator
5. **Error:** Fallback content with retry option

#### **Responsive Design**
- **Mobile:** Full-width card, touch-optimized buttons
- **Tablet:** Larger card with expanded summary text
- **Accessibility:** High contrast mode, screen reader support
- **Dark Mode:** Appropriate color schemes and contrast

### **Content Categories and Themes**

#### **Core Health Topics**
1. **Nutrition:** Healthy eating tips, food science, meal planning
2. **Exercise:** Movement science, workout tips, activity benefits
3. **Sleep:** Sleep hygiene, rest science, recovery optimization
4. **Stress Management:** Mindfulness, relaxation techniques, mental health
5. **Preventive Care:** Health screenings, early detection, wellness checks
6. **Lifestyle:** Habit formation, behavior change, daily wellness

#### **Content Personalization (V2)**
- User interest profile based on engagement history
- Health goal alignment (weight loss, fitness, stress management)
- Seasonal and timely content relevance
- Geographic and cultural considerations

---

## 🔧 Content Generation Pipeline

### **AI Content Creation Process**
```python
def generate_daily_content():
    """
    Daily content generation pipeline using Vertex AI.
    Runs at 3 AM UTC to ensure fresh content for global users.
    """
    
    # 1. Topic selection based on calendar and trends
    topic = select_daily_topic()
    
    # 2. Generate content using Vertex AI
    content = generate_ai_content(
        topic=topic,
        target_length=200,  # characters for summary
        tone="conversational",
        reading_level="8th_grade",
        include_actionable_tips=True
    )
    
    # 3. Content quality validation
    quality_score = validate_content_quality(content)
    if quality_score < 0.8:
        content = regenerate_with_feedback(content, quality_score)
    
    # 4. Store in database
    save_daily_content(content, topic)
    
    # 5. Trigger cache refresh notifications
    notify_content_refresh()
    
    return content

def select_daily_topic():
    """Intelligent topic selection based on multiple factors."""
    factors = {
        'seasonal_relevance': get_seasonal_health_topics(),
        'trending_health_news': get_health_trends(),
        'user_engagement_history': get_popular_topics(),
        'content_calendar': get_scheduled_topics(),
        'educational_value': get_high_impact_topics()
    }
    
    return weighted_topic_selection(factors)

def validate_content_quality(content):
    """Multi-factor content quality validation."""
    checks = {
        'factual_accuracy': check_medical_accuracy(content),
        'readability': calculate_readability_score(content),
        'engagement_potential': predict_engagement(content),
        'safety': medical_safety_review(content),
        'originality': check_content_uniqueness(content)
    }
    
    return aggregate_quality_score(checks)
```

### **Content Moderation and Safety**
```python
def medical_safety_review(content):
    """Ensure content meets medical safety standards."""
    
    safety_checks = [
        'no_medical_diagnoses',
        'no_prescription_advice', 
        'includes_disclaimer',
        'encourages_professional_consultation',
        'evidence_based_claims'
    ]
    
    for check in safety_checks:
        if not validate_safety_rule(content, check):
            return flag_for_human_review(content, check)
    
    return approve_content(content)
```

---

## 🔗 Integration Requirements

### **Epic 2.1: Engagement Events Logging**
- **Dependency:** Complete ✅
- **Integration:** Today Feed interactions logged as engagement events
- **Event Types:** 
  - `today_feed_view` (+1 momentum point, once per day)
  - `today_feed_click_external` (external link engagement)
  - `today_feed_share` (social sharing action)
  - `today_feed_bookmark` (save for later)

### **Epic 1.1: Momentum Meter Integration**
- **Dependency:** Expected Complete Week 3
- **Integration Point:** First daily Today Feed engagement awards +1 momentum
- **Real-time Update:** Immediate momentum meter refresh on interaction
- **Streak Bonus:** Consecutive daily engagement could trigger momentum bonuses

### **GCP Backend Integration**

#### **Cloud Run Content Service**
```typescript
// Cloud Run service endpoint structure
const CONTENT_SERVICE_CONFIG = {
  endpoint: '/today',
  method: 'GET',
  authentication: 'service_account',
  rate_limit: '1000_requests_per_hour',
  
  response_format: {
    title: 'string(60)',
    summary: 'string(200)', 
    link: 'url',
    category: 'enum[nutrition, exercise, sleep, stress, prevention, lifestyle]',
    confidence_score: 'float(0.0-1.0)',
    generated_at: 'iso_timestamp'
  }
}
```

#### **Vertex AI Integration**
```python
# Vertex AI content generation configuration
VERTEX_AI_CONFIG = {
    'model': 'text-bison@002',
    'temperature': 0.7,
    'max_output_tokens': 300,
    'top_p': 0.8,
    'top_k': 40,
    
    'prompt_template': """
    Generate an engaging daily health insight for a wellness app user.
    
    Topic: {topic}
    Target audience: Adults interested in preventive health
    Tone: Conversational, encouraging, science-based
    Length: Exactly 2 sentences for summary, under 200 characters
    
    Requirements:
    - Include one actionable tip
    - Reference credible research when relevant  
    - Avoid medical advice or diagnoses
    - Make it curiosity-driving and engaging
    
    Format:
    Title: [Engaging 60-character headline]
    Summary: [Exactly 2 sentences, under 200 characters]
    """
}
```

---

## 📊 Analytics & Monitoring

### **Key Performance Indicators**

#### **Content Engagement Metrics**
- Daily Today Feed open rate (target: 60%)
- Average session duration (target: 2+ minutes)
- Click-through rate to external content (target: 25%)
- Content sharing rate (target: 5%)
- User content ratings and feedback scores

#### **Content Quality Metrics**
- AI content confidence scores (target: >0.85)
- Content moderation flag rate (target: <2%)
- User reported content issues (target: <0.5%)
- Time from generation to publication (target: <30 minutes)

#### **Technical Performance Metrics**
- Content load time (target: <2 seconds)
- Cache hit rate (target: >95%)
- Offline content availability (target: 100%)
- API response time (target: <500ms)

### **Content Analytics Dashboard**
```sql
-- Daily content performance view
CREATE VIEW daily_content_performance AS
SELECT 
    dc.content_date,
    dc.title,
    dc.topic_category,
    COUNT(DISTINCT uci.user_id) as unique_viewers,
    COUNT(uci.id) FILTER (WHERE uci.interaction_type = 'view') as total_views,
    COUNT(uci.id) FILTER (WHERE uci.interaction_type = 'click') as total_clicks,
    COUNT(uci.id) FILTER (WHERE uci.interaction_type = 'share') as total_shares,
    AVG(uci.session_duration) as avg_session_duration,
    ROUND(
        COUNT(uci.id) FILTER (WHERE uci.interaction_type = 'click') * 100.0 / 
        NULLIF(COUNT(uci.id) FILTER (WHERE uci.interaction_type = 'view'), 0), 2
    ) as click_through_rate
FROM daily_feed_content dc
LEFT JOIN user_content_interactions uci ON dc.id = uci.content_id
WHERE dc.content_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY dc.id, dc.content_date, dc.title, dc.topic_category
ORDER BY dc.content_date DESC;
```

### **A/B Testing Framework**
- **Content Variations:** Test different titles, summaries, and CTAs
- **Timing Tests:** Optimal notification and refresh times
- **Format Testing:** Card layouts, visual elements, and interactions
- **Personalization:** Content category preferences and recommendations

---

## 🚀 Launch Strategy

### **Phase 1: MVP Launch (Week 6-7)**
- Basic Today Feed tile with static content rotation
- Manual content curation and updates
- Core engagement tracking and momentum integration
- Offline caching for basic content access

### **Phase 2: AI Integration (Week 8-9)**
- Automated content generation using Vertex AI
- Dynamic topic selection and content refresh
- Enhanced analytics and engagement tracking
- A/B testing framework implementation

### **Phase 3: Personalization (Future)**
- User interest profiling and content recommendations
- Personalized timing and notification optimization
- Advanced content formats (video, interactive elements)
- Social features (content sharing, discussions)

---

## ⚠️ Risks & Mitigation

### **Technical Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| AI content quality issues | High | Medium | Human moderation workflow |
| GCP service availability | High | Low | Fallback content cache |
| Content generation latency | Medium | Medium | Pre-generation and buffering |

### **Content Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Medical misinformation | Critical | Low | Medical review process |
| User content fatigue | Medium | Medium | Content variety and rotation |
| Low engagement rates | Medium | Medium | A/B testing and optimization |

### **Business Risks**
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Content generation costs | Medium | Medium | Budget monitoring and optimization |
| Copyright/licensing issues | High | Low | Original content focus |
| User privacy concerns | Medium | Low | Clear data usage policies |

---

## 📋 Acceptance Criteria

### **Epic-Level Acceptance Criteria**
- [ ] Today Feed tile displays prominently on main app screen
- [ ] Daily content refreshes automatically at local midnight
- [ ] Content loads within 2 seconds on average devices
- [ ] First daily engagement awards +1 momentum point
- [ ] Offline content access available for 24 hours minimum
- [ ] "Read more" functionality works smoothly with external links
- [ ] Content meets quality standards (readability, accuracy, engagement)
- [ ] User analytics tracking captures all interaction types
- [ ] A/B testing framework functional for content optimization
- [ ] Error handling graceful for network and content issues

### **Quality Assurance Requirements**
- [ ] Unit tests for content caching and display logic
- [ ] Integration tests for API endpoints and data flow
- [ ] UI tests for Today Feed tile interactions
- [ ] Performance tests for content load times
- [ ] Accessibility tests with screen readers
- [ ] Content quality tests for AI-generated material
- [ ] Security tests for external link handling

---

## 📚 Appendices

### **Appendix A: Content Examples**

#### **Sample Daily Health Insights**
1. **Sleep & Recovery**
   - Title: "The 90-Minute Sleep Cycle Secret"
   - Summary: "Your brain naturally cycles through sleep stages every 90 minutes. Timing your wake-up to align with these cycles can help you feel more refreshed and energized."

2. **Nutrition Science**
   - Title: "Why Eating Colors Boosts Your Health"
   - Summary: "Different colored fruits and vegetables contain unique antioxidants that protect different parts of your body. Aim for a rainbow of colors on your plate each day."

3. **Movement & Exercise**
   - Title: "The 2-Minute Activity Break Miracle"
   - Summary: "Just 2 minutes of movement every hour can counteract the negative effects of prolonged sitting. Even simple stretches or walking in place counts."

### **Appendix B: Technical Implementation**

#### **Flutter Widget Structure**
```dart
class TodayFeedTile extends StatefulWidget {
  final TodayFeedContent content;
  final VoidCallback? onTap;
  final bool isOffline;
  
  const TodayFeedTile({
    Key? key,
    required this.content,
    this.onTap,
    this.isOffline = false,
  }) : super(key: key);
}
```

#### **Content Model**
```dart
class TodayFeedContent {
  final int id;
  final DateTime contentDate;
  final String title;
  final String summary;
  final String? contentUrl;
  final String? externalLink;
  final String topicCategory;
  final double aiConfidenceScore;
  final bool hasUserEngaged;
  final bool momentumEarned;
  
  const TodayFeedContent({
    required this.id,
    required this.contentDate,
    required this.title,
    required this.summary,
    this.contentUrl,
    this.externalLink,
    required this.topicCategory,
    required this.aiConfidenceScore,
    this.hasUserEngaged = false,
    this.momentumEarned = false,
  });
}
```

### **Appendix C: Content Guidelines**

#### **Writing Standards**
- Reading level: 8th grade maximum
- Sentence length: 15-20 words average
- Tone: Conversational, encouraging, science-based
- Avoid: Medical diagnoses, prescription advice, fear-based messaging
- Include: Actionable tips, credible sources, positive framing

#### **Quality Checklist**
- [ ] Factually accurate and evidence-based
- [ ] Appropriate reading level and tone
- [ ] Includes actionable insight or tip
- [ ] Avoids medical advice or diagnoses
- [ ] Engaging and curiosity-driving
- [ ] Appropriate length (title <60 chars, summary <200 chars)

---

**Document Status:** 📝 Draft  
**Next Review:** Technical Team Approval  
**Approval Required:** Product Team, Clinical Team, Engineering Team  
**Target Start Date:** Week 6, Epic 1.3  

---

*This PRD serves as the definitive specification for the Today Feed feature. All implementation decisions should reference this document, and any changes must be approved through the standard change management process.* 