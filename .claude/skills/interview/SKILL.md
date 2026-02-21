---
name: interview
description: Interview the user in depth to produce a detailed specification document
argument-hint: [topic or instructions]
allowed-tools: AskUserQuestion, Write
disable-model-invocation: true
---

# Spec Interview

Interview the user thoroughly about the topic below, then produce a spec document.

<instructions>$ARGUMENTS</instructions>

## Interview Process

1. **Start with context**: Ask what they're building and why.

2. **Cover these categories** (adapt to topic):
   - Goals and non-goals
   - Users and stakeholders
   - Technical architecture and dependencies
   - UI/UX considerations
   - Data model
   - Security and permissions
   - Error handling and failure modes
   - Trade-offs and alternatives considered
   - Open questions

3. **Question guidelines**:
   - Ask one question at a time. Build on previous answers.
   - Go deep on uncertainty and complexity.
   - Avoid obvious questions. Challenge assumptions politely.

4. **Completion criteria**:
   - Cover at least 5 relevant categories and 8+ questions.
   - Ask: "Is there anything else to capture, or any area to go deeper on?"
   - If no, proceed to writing.

## Spec Output

Before writing, ask: "Where should I save the spec? (default: `specs/<topic-slug>.md`)"

Structure:
- Overview, Goals, Non-Goals, Background, Detailed Design, Trade-offs, Open Questions, References

Adapt sections based on what was discussed. Omit irrelevant sections.
