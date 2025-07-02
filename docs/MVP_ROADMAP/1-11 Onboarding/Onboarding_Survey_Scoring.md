
# Motivation Scoring – Internal vs External (BEE Onboarding)

This document defines a scoring algorithm to classify a patient's current motivational state as **External**, **Internal**, or **Mixed**, based on their responses to onboarding survey questions 13, 14, and 16. Rooted in Self-Determination Theory.

---

## 🎯 Scoring Inputs (Mapped by Question)

### Question 13: Why do you want to make changes?
| Answer | SDT Type | Score |
|--------|----------|-------|
| Improve how I feel | Identified/Internal | +2 |
| Look better | Introjected | +1 |
| Pressure from others | External | 0 |
| Take care of myself | Identified/Internal | +2 |
| For someone else | External | 0 |

### Question 14: What will be most satisfying?
| Answer | SDT Type | Score |
|--------|----------|-------|
| Proud of myself | Identified | +2 |
| Seen differently | Introjected/External | 0 |
| Proving I can do it | Introjected | +1 |
| Avoiding problems | Identified | +1 |

### Question 16: Preferred Coaching Style
| Answer | Coaching Type | Score |
|--------|----------------|-------|
| Right Hand | Autonomy-supportive → Internal | +2 |
| Cheerleader | Relational, flexible → Mixed | +1 |
| Drill Sergeant | Directive → External | 0 |
| I’m not sure | Neutral | 0 |

---

## 🧮 Scoring Algorithm

```python
total_score = Q13 + Q14 + Q16

if total_score >= 5:
    motivation_type = "Primarily Internal"
elif 3 <= total_score < 5:
    motivation_type = "Mixed / Internalizing"
elif 1 <= total_score < 3:
    motivation_type = "Primarily External"
else:
    motivation_type = "External or Uncertain"
```

---

## 🧠 How AI Should Use This

| Score Range | Label | Implications for Coaching |
|-------------|-------|----------------------------|
| 6–7 | Internal | Empower, reflect, identity-based goals |
| 3–5 | Mixed / Internalizing | Highlight meaning, ask deeper questions |
| 1–2 | External | Focus on structure, support small wins |
| 0 | Unclear / Amotivated | Use curiosity, spark value discovery |

---

**Note:** Scores are not shown to users. They are used to adjust tone, framing, and intervention strategies for both AI and human coaches.
