## 📩 EPIC 1.4 In-App Messaging Strategy – AI Coach Push Notifications

## 🔧 Feature Overview

Enable the AI Coach to send proactive push notifications to users (e.g., “Great work finishing your workout!”), which users can tap to open the app, view the coach message, and optionally reply within the chat interface.

🔁 User Flow
	1.	AI Coach triggers a message
            Example: After detecting workout completion
	2.	Push notification is sent
            Example: "👏 Great work finishing your workout! Want to log how you feel?"
	3.	User taps the notification
            App launches via deep link: myapp://coach?chatPromptId=12345
	4.	User lands on AI Coach screen
            The chat screen opens directly to the existing coach conversation.
            The coach message is pre-rendered as the most recent message.
            Input bar is active and focused for user reply.
            Optionally show: “Coach is typing…” for realism.

📌 UX and UI Guidelines
	•	Coach message should appear as a natural part of the existing thread, not in a new isolated screen.
	•	If user doesn’t open the notification:
	•	Show a badge or notification dot on the bottom nav Coach icon.
	•	When opened later, highlight the most recent unread coach message.  

🚀 Technical Implementation

🔗 Deep Linking
	•	Use a deep link format to route users directly to the Coach screen with an optional chatPromptId param.
	•	Example: myapp://coach?chatPromptId=456

💬 Chat Thread Integration
	•	The AI Coach message should:
	•	Be injected into the thread using chatPromptId as a unique message reference.
	•	Be persisted as part of the message history.
	•	Appear with a timestamp and sender (“Coach”).

📱 Notification Triggering
	•	Trigger conditions:
	•	E.g., on workout completion, after journal entries, goal milestones
	•	Backend or LLM determines message timing and content
	•	Messages are queued and sent via Firebase Cloud Messaging (or equivalent)


🧪 Future Optional Enhancements

Feature                     Description
Quick Reply Buttons         “Log Mood”, “Not Today”, “Plan Tomorrow”
Voice Reply                 Enable audio input for low-friction responses
Smart Summary Card          Context box above the chat: “🏋️ 30-min workout logged”
