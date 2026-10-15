---
name: resume-handoff
description: Warm-resume a session that died (usage limit, crash, compaction, next-day pickup). Reads the auto-written handoff for this directory and reconstructs state instead of re-exploring from zero. Use when the user says "ran out of tokens, proceed", "continue where you left off", "Claude crashed", "picking this up later", "where were we", or any resume-after-interruption phrasing.
---

# resume-handoff

The `handoff.sh` hook (SessionEnd + PreCompact) writes
`~/.claude/handoffs/<slug>.md`, where `<slug>` is the session cwd with `/` and `.`
replaced by `-` and the leading dash dropped. Example: `/home/me/hq/repos/foo` →
`home-me-hq-repos-foo`.

## Procedure

1. Compute the slug for the current cwd and read that handoff file. If it's
   missing, `ls -t ~/.claude/handoffs/ | head` and pick the closest match. Say
   which one you picked.
2. **Check it against live state before trusting it.** Run `git status` and
   `git log -3 --oneline`. The handoff is a snapshot, so if git moved since
   `written:`, git wins. Say so in one line.
3. Check for a richer note: the latest end-of-day note or session log for this
   work, if one exists.
4. Reply in at most 8 lines: what the thread was, where it stopped, what's
   uncommitted, and the next step you propose. Then wait, unless the user said
   "proceed".

## Rules

- Don't re-explore the codebase from scratch when the handoff names the files.
- Don't redo work the git log shows as done.
- A handoff whose "Last user messages" is empty still gives you git state, so use it.
