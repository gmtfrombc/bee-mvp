Below are the clarifying questions I have for each section.

────────────────────────────────────────
1. Components in Scope
────────────────────────────────────────
1. Quick Suggestion chips  
   • Are “How am I doing?” and “What’s next?” the final, user-facing strings (any localization needs)?  Yes, they are the final strings for MVP
   • Do you already have preferred icons or should we select from the existing design system?  Select from existing design system--appropriate for the strings
   • Should the chips persist at the top of the thread or only appear in an “input tray” area? They should replace the existing chips--i.e., in the same place.

2. Conversation thread UI  
   • Any brand or accessibility guidelines (font size, bubble colors, etc.) we must adhere to beyond the global theme?  Just stay with the global theme
   • What is the exact copy for the initial system greeting?  Hi <patient first name> (currently hardcoded as Sarah--which we can keep for demo purposes), what can I help you with today?
   • Is typing-indicator animation in scope for this sprint? Yes, it is scope for this sprint.

3. Side Drawer (chat history)  
   • How should each chat be titled—timestamp only (“Jun 19, 10:34 AM”) or derived from the first user message?  I want to mimick the ChatGPT mobile UX - so let's not put in a date, just a short title based on the question (like ChatGPT)
   • Do we need a confirmation dialog before deleting a chat?  Yes. We could do a swipe (or press) and then 'Okay to delete' modal message (yes/cancel)
   • Is there a maximum number of conversations to display or any pagination needed? Again, use standard best practice. If you have access to ChatGPT it looks like there is existing messages, with 'lazy loading' of additional chunks when the user scrolls to the end

4. User Feedback Capture  
   • Slider (1-10) + free-text sounds good—should submitting feedback be mandatory before the user can continue chatting?  No. They can have the option to cancel (i.e., not give feedback)
   • Where in the UI should the modal/inline widget appear—immediately below the coach’s reply or as an overlay?  I'm not sure what you mean here--can you rephrase or give more details?
   • Any additional metadata to store (e.g., momentum score at time of feedback)? Yes, that would be good.

5. Prompt Logic (backend)  
   • Momentum: confirm we’re using the existing 7-day moving average column—name/path in DB?  Yes. that should be the momementum score (maybe want to confirm?)
   • Steps & sleep: which exact tables/columns hold “latest 24 h” values?  NOTE: CHANGE IN PLANS. We are collecting, sleep, steps, resting heart rate (currently we are just recording average--but will change to resting), and active energy (calories). I don't know which columns they are in--we'll need to audit the db. If the columns aren't created yet--we will need to do so 
   • Are there token-length limits we must enforce pre-OpenAI call?  Not for now--but we should record this and plan to manage in the future.
   • Any other health metrics you already know will be “future extra metrics” so we can design flexible schema? HRV (heart rate variability), 'DRS - Daily Readiness Score' (subjective, daily assessment), PHQ-9 (depression score) GAD-7 (anxiety score), VO2 max, Continuous Glucose Monitor (CGM)

6. Future Voice Chat  
   • No questions; acknowledging it is out-of-scope for the current sprint.

────────────────────────────────────────
2. Observed Defects & Gaps
────────────────────────────────────────
AC-01 Quick Suggestions  
   • Besides renaming, do you have final icon assets / Figma references? Will just use existing/available icon assets for now

AC-02 “How am I doing?” dynamic prompt  
   • Confirm the algorithmic formula: 7-day momentum avg + yesterday’s steps + last-night sleep hours?  
Look at 
1. DRS (daily readiness score--needs to be built) today's score versus 3 day, 7 day and 30 day average (if available)
2. Sleep - last night's sleep versus 3, 7, and 30 day averages
3. Steps - yesterday's steps versus 3, 7, 30 day averages
4. Weight - last weight (if within the last 7 days) versus 3, 7, 30 day averages
5. Momentum Score (rising, falling, stable) - as above, most recent score versus 3, 7, 30 day average
That is all we will do to start. We will be adding additional metrics in the future

   • Any tonal guidelines (e.g., friendly, clinical)?. Friendy and motivational - focus on gentle (not contrived) positive feedback motivation, accountability, 

AC-03 “What’s next?” prompt  
   • The three actionable suggestions—should they always map to physical activity, sleep hygiene, and mindfulness, or vary? The action steps should relate back to what the patient's priorities--what they are working on with their health coach. This will come from an 'action_steps' table (to be created), messages and other interactions, as well as intake surveys. These will be suggestions and will map back to the current momentum. If momentum is low, then the suggestions will be 'defensive' - for example, take 10 minutes to yourself in a way that is relaxing, call a friend or loved one etc., If momentum is high--it's more of a 'What do you want to accomplish today', Add 10 minutes to your workout? Call up a friend you haven't talked to in a while, etc. There are no specifics right now, but we can explore options--for example, create a canonical table that gives options that can be sent in the prompt. 

AC-04 User feedback capture  
   • Confirm DB table name/columns: `coach_feedback (user_id UUID, timestamp TIMESTAMPTZ, rating INT, text TEXT)` acceptable? Yes, looks good
   • Any analytics events beyond what’s listed (`ai_feedback_submitted`)? Not for now, You can create a to-do around this.

AC-05 Conversation history (drawer)  
   • Should deleting a chat also delete its messages in the backend or just hide them client-side? Just hide it--we should retain all messages.
   • Any filtering (e.g., only show chats from last 30 days)? Again, follow ChatGPT showing a list of previous messages, with 'lazy loading' of older messages

AC-06 “New chat” button  
   • Position: top-right of drawer per spec—icon only or icon + label? ChatGPT has it on top right of the left-sided drawer--it's an icon only

AC-07 System greeting rewrite  
   • Is Product already drafting the copy, or should we propose wording? You can propose wording

Let me know the answers/clarifications, and I’ll proceed.