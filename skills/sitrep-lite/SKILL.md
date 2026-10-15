---
name: sitrep-lite
description: Read-only end-of-session or end-of-day status for work in shared team repos. Reports git state across the repos touched, open questions, and tomorrow's first step, then writes a short end-of-day note. Never commits, pushes, merges, prunes, or opens PRs. Use for "sitrep", "where are we", "wrap up", "end of day", "close out", "status".
---

# sitrep-lite

In a shared repo, close-out means **knowing** the state, not changing it. Every
outward or history-changing action (commit, push, PR, merge, branch delete,
stash drop) belongs to the user, one at a time, on request.

## Procedure

1. **Repos touched.** For each repo worked in this session (cwd, plus any the
   user named), collect in one pass: `git -C <repo> status --short`,
   `git -C <repo> branch --show-current`,
   `git -C <repo> rev-list --left-right --count @{u}...HEAD` (behind / ahead;
   the three-dot form is the one that can show BEHIND), and `git -C <repo> stash list`.
2. **Open PRs by the user**, if `gh` is authenticated:
   `gh pr list --author @me --state open`, plus review state and CI.
3. **Classify uncommitted work** per repo: intended change, debug leftovers,
   build output that should be gitignored, unknown. Recommend; don't act.
4. **Write the end-of-day note** at `~/notes/daily/YYYY-MM-DD.md`, or the
   location the user's CLAUDE.md names. Append if it exists:
   - Done today (facts, with commit SHAs or PR numbers)
   - In flight (repo, branch, what is uncommitted)
   - Open questions (who to ask)
   - Tomorrow's first step (one line)
5. **Report** as one table per repo plus the note path. Drop empty sections.

## Never

- `git commit`, `git push`, `git merge`, `git rebase`, `git reset`, `git stash drop`,
  `git branch -d/-D`, `gh pr create/merge/comment`, or any force flag.
- Delete files, even ones that look like leftovers. List them instead.
- Claim a state you didn't read this run.
