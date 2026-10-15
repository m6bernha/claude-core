---
name: parallel-chat-manifest
description: >
  Result-propagation convention for parallel Claude Code chats. Every spawned
  chat writes a small manifest at close; the parent (or any later session)
  reads unread manifests before continuing. Use in BOTH directions: (a) when a
  chat is spawned from / alongside another session ("spawn a parallel chat",
  "this chat was opened from another session"), register + close out with a
  manifest; (b) when resuming a session that spawned parallel work, list and
  ingest manifests. Pairs with superpowers-worktrees (isolation) — this skill
  covers the RETURN path that worktrees don't.
---

# parallel-chat-manifest — parallel results must come home

## Why this exists

Parallel chats complete their work, but their results never propagate back
to the session that spawned them, so the user can't tell what ran or why.
Isolation (worktrees) is well documented; the return path usually is not.

## Manifest location + format

`~/.claude/state/parallel/<YYYY-MM-DD>-<slug>.md` (machine-local; state/ is
gitignored by design — manifests are session plumbing, not knowledge).

```markdown
# <short title>
- status: OPEN | DONE | BLOCKED | ABANDONED
- spawned-by: <parent project/session description, as told to this chat>
- opened: <ISO date>  closed: <ISO date or ->
- goal: <one sentence, verbatim from the spawn instruction if possible>

## Result (fill at close)
<3-10 lines: what was decided/produced, where artifacts landed (paths, URLs,
commits), what is left undone>

## Ingest-by
<who should read this: e.g. "the parent session", "any session in this repo">
```

## Rules

1. **On spawn** (you are the spawned chat, or you are telling the user to open
   one): create the manifest immediately with `status: OPEN` — the parent must
   be able to see the work exists even if this chat dies.
2. **On close** (work done, or session ending): fill `## Result`, set status.
   The Stop/SessionEnd micro-handoff hook does NOT do this for you — the
   manifest needs the semantic summary only you can write.
3. **On resume / in the parent**: `ls ~/.claude/state/parallel/` — read every
   OPEN/DONE manifest newer than your last touchpoint, summarize them to the
   user in 1 line each, then mark ingested ones by renaming status to
   `DONE (ingested <date>)`.
4. Anything of durable value graduates OUT of the manifest: decisions → memory
   or ADRs; artifacts → the project repo; next actions → the parent's
   plan file. The manifest is a hand-off buffer, not storage.
