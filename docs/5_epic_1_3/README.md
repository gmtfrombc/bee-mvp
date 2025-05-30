# Epic 1.3: Today Feed (AI Daily Brief)

**Module:** Core Mobile Experience  
**Status:** ⚪ Planned  
**Dependencies:** Epic 2.1 ✅ Complete, Epic 1.1 🟡 In Progress  
**Timeline:** Week 6-7 (7 weeks, 288 hours)

---

## 📋 **Epic Overview**

Daily AI-generated health topics to spark curiosity and engagement through single-focus, educational content that integrates with the momentum meter system.

### **Key Features**
- **AI Content Generation:** Vertex AI-powered daily health insights
- **Smart Caching:** 24-hour refresh with offline fallback
- **Momentum Integration:** +1 point for daily engagement
- **Quality Assurance:** Medical safety review and content validation

---

## 📚 **Documentation**

### **Core Documents**
- **[prd-today-feed.md](./prd-today-feed.md)** - Complete product requirements
- **[tasks-today-feed.md](./tasks-today-feed.md)** - Detailed task breakdown

### **Implementation Guides**
- **[design-specs-today-feed-tile.md](./design-specs-today-feed-tile.md)** ✅ Complete - TodayFeedTile design specifications  
- **Flutter Today Feed widget implementation** ✅ Complete - TodayFeedTile StatefulWidget with MD3
- GCP Cloud Run setup and Vertex AI integration ✅ Complete
- Content caching and offline strategy (Coming Soon)
- Momentum meter integration patterns (Coming Soon)
- AI content quality validation ✅ Complete

### **Operational Documentation** (Coming Soon)
- Content analytics and monitoring
- Content safety and moderation procedures
- A/B testing framework usage
- Performance optimization guidelines

---

## 🎯 **Milestones**

| Milestone | Focus | Duration | Dependencies |
|-----------|-------|----------|--------------|
| **M1.3.1** | Content Pipeline | Week 6 | GCP setup |
| **M1.3.2** | Feed UI Component | Week 6 | Design system |
| **M1.3.3** | Caching Strategy | Week 7 | M1.3.2 |
| **M1.3.4** | Momentum Integration | Week 7 | Epic 1.1 |
| **M1.3.5** | Testing & Analytics | Week 7 | All previous |

### **Success Criteria**
- 60% daily engagement rate with Today Feed content
- <2 second content load times with 95%+ cache hit rate
- AI content meets quality standards (>0.85 confidence)
- Seamless momentum meter integration (+1 point per day)
- 80%+ test coverage across all components

---

## 🔧 **Technical Architecture**

### **Backend Services**
- **GCP Cloud Run:** Content generation service
- **Vertex AI:** text-bison model for content creation
- **Supabase:** Content metadata and user interactions
- **Cloud Storage:** Content assets and media

### **Frontend Components**
- **TodayFeedTile:** Material Design 3 widget
- **Content Caching:** shared_preferences + local storage
- **Real-time Updates:** Riverpod state management
- **Momentum Integration:** Engagement events logging

### **Content Pipeline**
```
3 AM UTC → Vertex AI → Quality Validation → Content Storage → CDN → App Cache
```

---

## 📊 **Current Status**

### **Progress Overview**
- **Tasks Completed:** 13/50 (26%)
- **Milestones Complete:** 1/5 (20%) - M1.3.1 ✅ Complete, M1.3.2 🟡 In Progress
- **Estimated Hours:** 288h total
- **Target Completion:** Week 7

### **Blockers & Dependencies**
- ⚪ GCP environment setup required
- 🟡 Epic 1.1 momentum meter integration needed
- ⚪ Content safety guidelines development
- ⚪ AI/ML team coordination for Vertex AI setup

---

## 🚀 **Getting Started**

### **Prerequisites**
1. Epic 2.1 (Engagement Events) complete ✅
2. GCP account with Vertex AI access
3. Flutter 3.32.0 development environment
4. Supabase project with RLS configured

### **Development Setup**
1. Configure GCP Cloud Run service
2. Set up Vertex AI content generation
3. Create Flutter Today Feed widget
4. Implement content caching strategy
5. Integrate with momentum meter system

### **Testing Strategy**
- Unit tests for content caching and AI integration
- Widget tests for UI components and interactions
- Integration tests for API and momentum meter connection
- Performance tests for load times and cache efficiency
- Content quality tests for AI-generated material

---

## 🎨 **Design Specifications**

### **Today Feed Tile Design**
- **Header:** "Today's Health Insight" with date
- **Content:** Engaging title (≤60 chars) + 2-sentence summary (≤200 chars)
- **Visual:** Health topic-related imagery
- **CTA:** "Read More" button with momentum indicator
- **States:** Fresh, Engaged, Loading, Offline, Error

### **Content Categories**
1. **Nutrition:** Food science, meal planning, healthy eating
2. **Exercise:** Movement benefits, workout tips, activity science  
3. **Sleep:** Sleep hygiene, recovery optimization, rest science
4. **Stress Management:** Mindfulness, relaxation, mental health
5. **Preventive Care:** Health screenings, early detection
6. **Lifestyle:** Habit formation, behavior change, wellness

---

## 📋 **Quality Standards**

### **Content Requirements**
- Reading level: 8th grade maximum
- Evidence-based health claims only
- No medical diagnoses or prescription advice
- Includes actionable tips and insights
- Engaging and curiosity-driving tone

### **Technical Requirements**
- <2 second content load times
- 95%+ cache hit rate for offline access
- WCAG AA accessibility compliance
- 60 FPS animations and interactions
- <10MB additional memory usage

### **Safety Standards**
- Medical accuracy verification
- Appropriate health disclaimers
- Professional consultation encouragement
- Human review for flagged content
- Content filtering and moderation

---

**Next Steps:** Begin M1.3.1 (Content Pipeline) development  
**Epic Owner:** Development Team  
**Stakeholders:** Product, AI/ML, Clinical, Content Teams 