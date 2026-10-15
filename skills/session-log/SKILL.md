---
name: session-log
description: Write an end-of-session summary to ~/.claude/session-logs/YYYY-MM-DD-<slug>.md so the next session can pick up without re-exploring. Use when the user says "session log", "log this session", "save session", "wrap up", "resume file", or when you're about to hit context limits and need a clean handoff.
---

# Session Log — Manual Memory Persistence

Claude Code sessions are ephemeral. Every new chat starts cold. Writing a short "what happened + what's next" file at the end of a working session lets the next one resume in 2KB of context instead of re-exploring the codebase.

## When to use

- User says "log this session", "save session", "wrap up", "resume file"
- About to hit context limits and want a clean handoff
- End of a long working block — especially if work will continue tomorrow
- After a hard debugging session, so the chain of reasoning isn't lost

## What to write

Create a file at `~/.claude/session-logs/YYYY-MM-DD-<short-slug>.md` with this structure:

```markdown
# Session log — {YYYY-MM-DD} — {slug}

## Objective
One sentence on what we were trying to accomplish.

## What worked (with evidence)
- Approach, file:line, and how we verified it worked (test passed, curl returned X, etc.)

## What failed
- Approach, file:line, error we got, why it didn't work

## What's left
- Concrete next task, with file paths
- Unknowns to investigate

## Handoff context
- Current branch / uncommitted changes
- Active processes / running services (ports, PIDs)
- Relevant file paths the next session should open first
```

## How to resume next session

Start the next Claude Code session by saying: "Read `~/.claude/session-logs/{file}.md` and continue from What's left." That bootstraps the new conversation with the minimum viable context — no re-exploration, no re-debugging.

## Rules

- Keep the file under ~50 lines. If it grows bigger, the resume hurts more than it helps.
- Put evidence with every "what worked" claim (commands run, test names, URLs checked). Memory without evidence is just vibes.
- One file per session. Don't accumulate into one mega-log.
- Do NOT include secrets, tokens, or full command outputs. Summarize.
