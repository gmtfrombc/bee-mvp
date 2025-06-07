# Adaptive Coach Recovery Plan

**Epic:** 1.3 · Adaptive AI Coach Foundation  
**Status:** 🚨 **CRITICAL** - Hardcoded responses instead of AI functionality  
**Created:** June 7, 2025  
**Timeline:** 5-7 days to restore full AI functionality

---

## 🎯 **Situation Overview**

### **Current State**
- ✅ **UI Interface**: Coach chat screen fully functional
- ❌ **AI Backend**: All responses are hardcoded ("That's a great question! Based on your momentum patterns...")
- ❌ **Personalization**: No user-specific responses
- ❌ **Momentum Integration**: No real momentum-based coaching
- ❌ **Emotional Intelligence**: No sentiment-aware responses
- ❌ **Today Feed Integration**: No content-aware discussions

### **Expected State** (According to Roadmap)
All AI functionality should be **operational** as part of Phase 1 milestones (M1.3.1-M1.3.8) marked "Complete"

### **Root Cause Analysis**
The issue is likely in **M1.3.1: AI Coaching Architecture** - if the foundation AI API integration isn't working, all dependent features default to hardcoded responses.

---

## 📋 **Recovery Strategy**

### **Approach: Cascade Fix**
1. **Focus on M1.3.1 first** - Fix core AI infrastructure
2. **Validate dependent milestones** - Ensure they use working AI
3. **Incremental testing** - One layer at a time

### **Success Metrics**
- **Phase 1**: Basic AI responses replace hardcoded text
- **Phase 2**: AI adapts to momentum state and user context
- **Phase 3**: Full personalization and emotional awareness

---

## 🔥 **Phase 1: Diagnostic & Infrastructure Audit** 
*Timeline: 1-2 days*

### **Objective**
Identify why M1.3.1 AI infrastructure isn't providing real AI responses

### **Tasks**

#### **T1.1: Edge Function Status Audit**
- [ ] **Check deployment status**
  ```bash
  supabase functions list
  supabase status
  ```
- [ ] **Verify `ai-coaching-engine` function exists and is running**
- [ ] **Check function logs for errors**
  ```bash
  supabase functions logs ai-coaching-engine
  ```
- [ ] **Document current function status**

#### **T1.2: API Configuration Audit**
- [ ] **Check environment variables**
  - OpenAI API key configured (in .env)
  - Correct environment (dev/prod)
- [ ] **Verify API key validity**
  - Test OpenAI connection independently
- [ ] **Check API rate limits and quotas**

#### **T1.3: Code Flow Analysis**
- [ ] **Trace chat message flow**
  - UI sends message → Backend service → AI engine
  - Identify where hardcoded response is injected
- [ ] **Check `coach_chat_screen.dart`**
  - Line ~100: `_simulateCoachResponse()` function
  - Verify if this calls real AI service or simulation
- [ ] **Check AI service implementation**
  - `functions/ai-coaching-engine/mod.ts`
  - Verify actual API calls vs mock responses

#### **T1.4: Database Integration Audit**
- [ ] **Verify conversation logging**
  - Check if user messages are stored
  - Check if AI responses are logged
- [ ] **Test momentum data pipeline**
  - Confirm momentum changes trigger AI coaching
  - Verify user pattern data availability

### **Phase 1 Deliverable**
📋 **Diagnostic Report** identifying exact blockers preventing real AI responses

---

## ⚡ **Phase 2: Fix Foundation Infrastructure**
*Timeline: 3-5 days*

### **Objective** 
Restore M1.3.1 AI infrastructure to provide real AI-generated responses

### **Tasks**

#### **T2.1: Deploy/Fix AI Coaching Engine**
- [ ] **Deploy `ai-coaching-engine` Edge Function**
  ```bash
  cd functions/ai-coaching-engine
  supabase functions deploy ai-coaching-engine
  ```
- [ ] **Configure production environment variables**
  ```bash
  supabase secrets set OPENAI_API_KEY=your_key
  ```
- [ ] **Test function deployment**
  ```bash
  curl -X POST https://your-project.supabase.co/functions/v1/ai-coaching-engine \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"user_id":"test","message":"Hello coach"}'
  ```

#### **T2.2: Replace Hardcoded Responses**
- [ ] **Update `coach_chat_screen.dart`**
  - Remove `_simulateCoachResponse()` hardcoded text
  - Replace with real API call to AI coaching engine
  - Add error handling for API failures
- [ ] **Implement real AI service calls**
  ```dart
  // Replace this:
  text: "That's a great question! Based on your momentum patterns..."
  
  // With this:
  final response = await AICoachingService.generateResponse(userMessage);
  text: response.message
  ```

#### **T2.3: Connect Data Pipeline**
- [ ] **Link momentum data to AI context**
  - Pass current momentum state to AI engine
  - Include recent momentum changes in AI prompt
- [ ] **Connect engagement events**
  - Pass user's recent activity to AI for context
  - Include Today Feed interactions in AI discussions
- [ ] **Test end-to-end data flow**
  - User action → Engagement event → Momentum update → AI coaching

#### **T2.4: Basic AI Response Testing**
- [ ] **Test with multiple user messages**
  - Verify each response is unique and contextual
  - Confirm no hardcoded text appears
- [ ] **Test with different momentum states**
  - Rising momentum: Should get encouraging/challenging responses
  - Needs Care: Should get supportive responses
- [ ] **Verify conversation memory**
  - Multi-turn conversations maintain context
  - AI references previous messages

### **Phase 2 Deliverable**
🎯 **Working AI Coach** providing unique, contextual responses to user messages

---

## 🔍 **Phase 3: Validate Dependent Features**
*Timeline: 2-3 days*

### **Objective**
Ensure all AI-dependent milestones work with restored infrastructure

### **Tasks**

#### **T3.1: Test Personalization Engine (M1.3.2)**
- [ ] **Verify user pattern analysis**
  - AI adapts to user's engagement history
  - Different users get different coaching styles
- [ ] **Test coaching persona assignment**
  - Rising momentum → Challenging persona
  - Needs Care → Supportive persona
  - Steady → Educational persona
- [ ] **Validate intervention triggers**
  - AI coaching activates when momentum drops
  - Frequency limits respected (max 3/day, 4hr gaps)

#### **T3.2: Test Conversation System (M1.3.3)**
- [ ] **Verify natural language understanding**
  - AI understands user questions and context
  - Responses feel conversational, not robotic
- [ ] **Test conversation flow**
  - Multi-turn conversations work smoothly
  - AI maintains context across message exchanges
- [ ] **Validate context awareness**
  - AI references Today Feed content when relevant
  - AI acknowledges recent momentum changes

#### **T3.3: Test Momentum Integration (M1.3.5)**
- [ ] **Test momentum change triggers**
  - Simulate momentum drop → Verify AI outreach
  - Simulate momentum improvement → Verify celebration
- [ ] **Test Today Feed integration**
  - User reads Today Feed → AI can discuss content
  - AI suggests actions based on Today Feed topics
- [ ] **Test progress celebration**
  - Achievement milestones trigger positive AI responses
  - Streak maintenance gets acknowledgment

#### **T3.4: Test Emotional Intelligence (M1.3.7)**
- [ ] **Test sentiment detection**
  - Positive user messages → Celebratory AI responses
  - Negative user messages → Supportive AI responses
  - Neutral messages → Educational AI responses
- [ ] **Verify emotional adaptation**
  - AI tone matches user emotional state
  - Visual indicators show emotional validation
- [ ] **Test emotional memory**
  - AI remembers user's emotional patterns
  - Responses consistent with user's emotional needs

#### **T3.5: Integration Testing**
- [ ] **Test complete user journeys**
  - Morning: Check momentum → Read Today Feed → Chat with AI
  - Evening: Momentum drops → Receive AI coaching → Respond
- [ ] **Test cross-feature integration**
  - All AI features work together seamlessly
  - No conflicts between different AI responses
- [ ] **Performance testing**
  - AI response times under 2 seconds
  - System handles multiple concurrent users

### **Phase 3 Deliverable**
✅ **Fully Functional AI Coach** with personalization, emotional intelligence, and momentum integration

---

## 📊 **Verification Checklist**

### **User Experience Tests**
- [ ] User sends message → Gets unique AI response (not hardcoded)
- [ ] AI references user's current momentum state
- [ ] AI adapts tone based on user's emotional state  
- [ ] AI can discuss Today Feed content when prompted
- [ ] AI proactively reaches out when momentum drops
- [ ] Different users get different coaching styles
- [ ] Multi-turn conversations feel natural

### **Technical Tests**
- [ ] Edge Functions deployed and accessible
- [ ] API keys configured and working
- [ ] Real AI API calls (no mock/simulation)
- [ ] Database logging all interactions
- [ ] Error handling prevents crashes
- [ ] Performance under 2 seconds per response

---

## 🎯 **Success Criteria**

### **Immediate Success (End of Phase 2)**
- ✅ **No hardcoded responses** - All messages generated by AI
- ✅ **Basic personalization** - Responses adapt to momentum state
- ✅ **Real-time functionality** - Live AI processing

### **Complete Success (End of Phase 3)**
- ✅ **Full personalization** - Individual coaching styles
- ✅ **Emotional intelligence** - Sentiment-aware responses  
- ✅ **Context awareness** - References momentum and Today Feed
- ✅ **Proactive coaching** - Automatic outreach on momentum changes
- ✅ **Conversation flow** - Natural multi-turn discussions

---

## 🚨 **Risk Mitigation**

### **If API Keys Are Missing**
- Configure in Supabase environment
- Test with minimal quota first

### **If Edge Functions Won't Deploy**
- Check Supabase project status
- Verify Docker environment setup
- Review function logs for deployment errors

### **If AI Responses Are Poor Quality**
- Review prompt engineering in `ai-coaching-engine`
- Test with AI model (GPT-4)
- Adjust system prompts for healthcare context

### **If Performance Is Slow**
- Implement response caching
- Optimize AI prompts for faster processing
- Add request timeout handling

---

## 📅 **Timeline & Resource Allocation**

| Phase | Duration | Resources | Priority |
|-------|----------|-----------|----------|
| **Phase 1: Diagnostic** | 1-2 days | 1 developer | 🔴 Critical |
| **Phase 2: Fix Foundation** | 3-5 days | 1-2 developers | 🔴 Critical |  
| **Phase 3: Validate Features** | 2-3 days | 1 developer | 🟡 High |
| **Total** | **5-7 days** | **1-2 developers** | **🔴 Critical** |

---

**Recovery Plan Owner**: Development Team  
**Stakeholders**: Product Team, User Experience Team  
**Next Review**: Daily standups during recovery period  
**Success Metric**: 0% hardcoded responses, 100% AI-generated coaching

---

*Last Updated: January 6, 2025*
*Status: Ready for immediate execution* 