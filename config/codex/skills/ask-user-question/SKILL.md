---
name: ask-user-question
description: Run a structured interview to gather requirements one question at a time using AskUserQuestion-style prompts. Use when the user says "interview me", "ask me questions about", "use the ask user skill", "use your interview skill", or when requirements are ambiguous and need a guided, option-based questionnaire before planning or implementation.
---

# Ask User Question

## Overview

Use a structured interview to collect missing context before planning or execution. Ask informed, option-based questions with clear tradeoffs and wait for answers before moving forward.

## Interview Workflow

1. Explore before asking.
   - Inspect the codebase and current patterns.
   - Note constraints, conventions, and likely decision points.
2. Identify critical decisions.
   - Focus on architecture, scope, and rework risk.
   - Defer implementation details until direction is clear.
3. Design a structured question.
   - Ask one question at a time by default.
   - Offer 2-4 mutually exclusive options.
   - Lead with a recommended option based on discovery.
4. Ask and wait.
   - Use the AskUserQuestion tool, or the equivalent `request_user_input` tool when available.
   - Do not proceed until the user answers or explicitly declines.
5. Iterate.
   - If an answer introduces new unknowns, ask the next focused question.
   - When clarity is sufficient, switch to planning or implementation.

## Question Design Rules

- Keep question headers at 12 characters or fewer.
- Make options concrete, actionable, and mutually exclusive.
- Explain why each option fits and the tradeoff it introduces.
- Ground each question in exploration; do not ask blind questions.
- Prefer single-question turns unless batching is clearly necessary.

## AskUserQuestion Structure

Use this structure:

```yaml
Question:
  text: <specific question with context>
  header: <short tag, max 12 chars>
  options:
    - label: <option label>
      description: <tradeoff description>
    - label: <option label>
      description: <tradeoff description>
  multiSelect: false
```

Set `multiSelect: true` only when multiple options can legitimately apply.

If the tool is unavailable, present the same structure in markdown and ask the user to reply with an option label or `Other`.

## Trigger Examples

- "Interview me about this project."
- "Ask me questions about the requirements."
- "Use the ask user skill."
- "Use your interview skill."
