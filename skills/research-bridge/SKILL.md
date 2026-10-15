---
name: research-bridge
description: >
  Convert a completed multi-agent research fan-out into an actionable,
  context-cheap implementation plan. Use immediately after parallel research
  agents / parallel chats finish, when the user says "ingest all of this and
  implement what you determine best fit", "synthesize the research", "what do
  we build from these findings", or when raw agent findings are about to be
  pasted into the main window. Prevents the two failure modes from the
  2026-07-03 audit: context death from ingesting 1500-line agent dumps, and
  research that lands but never turns into code.
---

# research-bridge — findings → ranked, done-when'd TODO

## The two failure modes this kills

1. **Context death**: 6–8 agents × 200+ lines each synthesized in-window →
   compaction → resumed cold.
2. **The implicit handoff**: findings arrive, "wire this in" is undefined, so
   each finding gets re-litigated or dropped.

## Procedure

1. **Findings stay on disk.** Collect every agent output into
   `<project>/.claude/research/<date>-<topic>/raw/` (one file per agent). If
   outputs only exist in chat, write them to disk NOW before synthesizing.
   Never paste more than the synthesis back into the window.

2. **Dedupe + cluster** (a single subagent pass over the raw files, Sonnet):
   merge duplicate findings, group by theme, drop anything with no evidence.

3. **Map each surviving finding to an action**: the module/file it changes, or
   the decision it feeds. A finding with no action mapping goes to a
   `parked.md` list with one line of why.

4. **Rank + gate.** Produce `HANDOFF.md` in the same folder:

   ```markdown
   # Research handoff — <topic> (<date>)
   ## Ranked build list
   1. <action> — from findings <ids>. DONE WHEN: <objective criteria —
      tests pass / rubric >= N / file X exists and does Y>. Depends on: <—/#>.
   2. ...
   ## Parked (no action yet)
   ## Open questions for the user (max 3)
   ```

5. **Return to chat**: the top-10 lines of the build list only, plus the path.
   The main window gets the map, not the territory.

## Done-when discipline (applies to the NEXT step too)

When items from the build list are dispatched to implementation agents, each
spawn carries its DONE WHEN clause verbatim. Agents are not done when they say
so; they are done when the clause holds.
