---
name: census-then-build
description: >
  Before any repo-wide rework, spend a parallel subagent fan-out producing a
  committed, line-level INVENTORY of every affected site — then build from the
  inventory instead of discovering sites inline. Use when the change is
  cross-cutting rather than local: "everywhere we do X", "replace this pattern
  across the repo", "audit every call site", "repo-wide", "all the places that",
  "sweep", a migration, a deprecation, a convention change, or any rework whose
  true scope is unknown at the start. Also use when a previous attempt at the
  same rework missed sites. Do NOT use for a change confined to one file or a
  handful of known call sites — the fan-out is not free.
---

# census-then-build — map the whole surface before touching any of it

Proven on the 2026-07-29 inference-layer run: a seven-agent census fan-out
(~640k subagent tokens) bought line-level coverage of ~130 sites. Done inline it
would have consumed the entire main context window, and — the real cost —
coverage would have been whatever the main thread happened to stumble across.

## The failure this kills

Inline discovery makes coverage a function of luck and remaining context. You
find sites while editing, the window fills, compaction lands, and the sweep ends
where the context ended rather than where the pattern ended. Nobody can tell the
difference afterward, because a partial sweep and a complete one look identical
from the diff. The census makes coverage an artifact you can count and audit.

## Step 0 — Scope probe (always; ~30 seconds, two greps)

This skill auto-invokes on repo-wide phrasing, so it must be able to decline
itself. Before spawning anything, grep the crudest signature of the pattern and
count hits and distinct files. Then:

| hits | action |
|---|---|
| < ~10 sites in < ~5 files | **No fan-out.** Say "scope probe: N sites in M files, censusing inline" and just do the work. Paying 6 agents here would cost tokens, not save them. |
| ~10–40 | **Lightweight census**: 2–3 slices, or one Sonnet pass writing the inventory. Still on disk, still classified. |
| > ~40, or the grep can't express the pattern (it's semantic, not textual) | **Full fan-out**, Phase 1 below. The ungreppable case is the strongest signal for it — that's exactly what inline discovery cannot cover. |

Report the probe number before choosing. A fan-out launched without a stated
count is the same guessing this skill exists to replace.

## Phase 1 — Census (no edits, none, not even obvious ones)

1. **Partition the repo into disjoint slices**, one per agent, along package /
   subsystem / directory boundaries. Disjoint matters more than balanced: two
   agents sharing a directory produce duplicate rows with different ids and you
   lose the count. Name the exact paths in each agent's prompt; "the rest of the
   repo" is not a slice. 5–8 slices is the usual shape.

2. **Each agent enumerates, classifies, and cites.** Every site is one row:

   | field | content |
   |---|---|
   | `id` | `<slice>-NNN`, stable, never renumbered |
   | `site` | `path/to/file.py:LINE` |
   | `what` | one line: what the code does here |
   | `stands_for` | the intent this code is a stand-in for (the point of the rework) |
   | `class` | `load-bearing` (drives an irreversible choice) / `advisory` / `decorative` |
   | `evidence` | the call path or caller that makes the class true |

   Classification is the deliverable, not the list. An unclassified list is a
   grep result and you did not need seven agents for it.

3. **Model routing**: Haiku for pure "find every occurrence" slices; Sonnet when
   the row requires judging what a site is *for*. Opus only for a slice touching
   security, auth, or money. Announce the choice per spawn.

4. **Done-when, verbatim in every spawn**: "Every file under <paths> has been
   opened or explicitly ruled out by extension. Output is rows only — no prose,
   no recommendations, no edits. A site you are unsure how to classify is a row
   with `class: unsure` and a reason, never an omission."

5. **Rows land on disk, not in chat**: `docs/research/<date>-<topic>/census.md`
   (or the repo's research convention). Chat gets counts per slice, the class
   histogram, and the path. Never paste the census into the window.

## Phase 2 — Verify the census before trusting it

A census you did not check is a confidence generator. Two cheap checks:

- **Mechanical floor**: grep the repo for the pattern's crudest signature and
  compare the hit count to the row count. Rows ≥ hits, or a slice was skipped.
  If rows massively exceed hits, agents are inventing or double-counting.
- **Completeness critic**: one agent whose only job is "what is missing — a
  directory nobody was assigned, a file extension nobody read, a call path with
  no row?" What it finds becomes census rows, not a footnote.

State the coverage number out loud before building. If a slice failed or was
capped, say which one — a silent gap reads as complete coverage forever after.

## Phase 3 — Build from the inventory

- The census **is** the work list. Rework `load-bearing` rows first; `advisory`
  next; `decorative` rows are often correctly left alone — say so explicitly
  rather than sweeping them for consistency.
- Every commit message names the row ids it closes. Every row gets a status:
  `done` / `unchanged, because <reason>` / `parked`. A row with no status at the
  end means the sweep is not finished, which is exactly the fact inline
  discovery hides.
- Re-run the mechanical floor grep at the end. New hits mean the rework
  introduced new instances of what it was removing.
- Commit the census with its statuses. Its second life is the regression check
  the next time this pattern is touched.

## Anti-patterns

- **Editing during census.** One "while I'm here" fix and the agent's remaining
  slice is now surveyed against a moved target. Census reads; build writes.
- **Skipping census because the scope "feels small".** The scope feeling small
  is the symptom the census exists to test. Cheap version: run it with 2 agents.
- **A census with no `class` column** — an unranked list of 130 sites is a
  second problem, not a map.
- **Paying the fan-out for a known, enumerable set.** Three known call sites do
  not need a census. Say so and just do the work.

## Related

- `research-bridge` — the same disk-not-window discipline for *external
  research* findings; this skill is its in-repo sibling.
- `superpowers-sdd` — takes over at Phase 3 when the build spans many files.
- `context-budget` — if the census itself is what blew the window, the fan-out
  was under-partitioned.
