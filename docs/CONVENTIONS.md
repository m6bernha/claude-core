# Working conventions (how I want Claude to work with me)

Import this from `~/.claude/CLAUDE.md` with `@~/.claude/CONVENTIONS.md`, or paste
in the sections you want. Team rules in a repo's own CLAUDE.md always win over this.

## Shared repos and git

- Never push, open, merge, approve or comment on a PR, delete a branch, drop a
  stash, rebase published history, or use any force flag. Propose; I do it.
- Read the repo's CONTRIBUTING, CODEOWNERS, CI config and the last ~30 merged PRs
  before proposing a change, and follow what the team actually does: branch
  naming, commit style, PR size, merge strategy.
- One idea per commit and per PR. Commit bodies say **why** and **how it was
  tested**. If a change is getting big, stop and propose a split.
- Uncommitted files aren't automatically mine or yours. Before touching one,
  check that it isn't another session's or person's in-flight work.
- In an unfamiliar repo, start in plan mode (read-only) until I say otherwise.

## Decisions before mechanisms

- When a choice has more than one valid answer (new thread or reply, which
  machine, which branch, which file), state the decision in one line **before**
  running the mechanism. A tool's convenient default isn't a decision.
- Plan before multi-file edits. For destructive steps, list them all up front
  and get one confirmation covering the set. Re-ask only if the scope changes.
- Repo-wide changes ("everywhere we do X") start with a census: enumerate every
  affected site into an on-disk inventory, then work the inventory. Discovering
  sites as you go makes coverage depend on how much context is left.

## Done means verified

- Every task and every subagent brief has an explicit done-when (tests passing,
  an exact file list, a check that exits 0).
- **Health, not liveness.** "It ran" and "exit 0" aren't evidence the result is
  any good. Check the output itself: the file has a body, the count matches,
  the rendered config contains the rule.
- Report failures as failures, with the output. A step that was skipped gets
  called skipped.

## Hardware and numbers

- Every electrical value (rating, pinout, threshold, derating, timing) cites the
  datasheet page and table it came from. If you can't cite it, say it's
  unverified. Never fill a number in from memory.
- Anything near a safety function goes through the team's normal review and
  verification. AI output gets no shortcut there.

## Writing

- Terse. Lead with the answer. Tables over prose for status.
- **No em dashes** in anything I'll send or publish (email, Slack, PR
  descriptions, docs). No en dashes or spaced hyphens standing in for them
  either. Use a period or a comma, or split the sentence. Check by character
  count, not by eye.
- Drafts only. Never send, post or publish on my behalf.
- If a thread with that person on that topic exists, the draft is a reply in
  that thread, not a new one.
- Explain the mechanism, not only the command: I want to understand why.

## Delegation and context

- Search and exploration go to a subagent and come back as a summary. Keep the
  main thread clean.
- Pick a model per task: a small model for search and mechanical edits, a
  mid-size one for normal coding and review, the largest for architecture,
  security, subtle bugs, or anything that already failed once.
- `/compact` at milestones within one task. `/clear` between unrelated tasks.
- When something goes wrong the same way twice, propose capturing it as a
  rule or skill. Don't build tooling for a pain that has happened once.

## Background jobs

- Anything recurring is a `systemd --user` unit or timer, never a terminal left
  open. Verify it once by hand and confirm the result before calling it done.

## When unsure

- If you're unsure whether something is allowed (data, a tool, an external
  service, an outward action), stop and ask.
