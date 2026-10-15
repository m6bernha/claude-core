# Engineering lessons (generic, earned the hard way)

Each one cost real time once. Read the ones whose trigger matches what you're doing.

1. **A monitor that checks liveness reports green while the thing degrades.**
   "Did it run" and "is it recent" aren't "is the result good". Any exit-code
   check that feeds a success message, or a freshness marker written on
   completion rather than on verification, is suspect.

2. **Hooks and jobs that write state must verify the body.** Read bounded
   input (the tail, not the whole file), write to a temp file, check the
   content is non-trivial, then rename. A truncate-then-write that dies midway
   leaves an empty file that looks like a success.

3. **temp + rename can strand orphans the consumer's glob never sees.** A killed
   writer leaves `x.json.tmp123` while the reader globs `*.json`. Add an
   age-gated cleanup, and make it age-gated so it never eats a live write.

4. **Check the rendered config, not the source.** A merge step (jq `*`, YAML
   anchors, overlay files) can silently replace arrays, so the source has 18
   deny rules and the live file has 0. Count what the program actually loads.

5. **Guards must not restate their own trigger.** A message that says "threshold
   of 10" goes stale the day someone changes it to 3. Interpolate the variable,
   or point at the file and name nothing.

6. **Backlog items carry diagnostics, not conclusions.** Write "run this check
   and act on its output", never "these 7 things are stale". The conclusion
   goes stale, and someone acts on it weeks later.

7. **Unattended network calls must never wait for a human.** A credential prompt
   that can't be shown hangs the job forever, and every later run stacks behind
   it. Disable prompts (`GIT_TERMINAL_PROMPT=0`) and wrap the call in `timeout`.

8. **Line endings and encodings break pipelines quietly.** Tool output with `\r`
   makes string comparisons fail without an error, and non-UTF-8 consoles crash
   on Unicode. Normalize (`tr -d '\r'`) and set UTF-8 explicitly at boundaries.

9. **A selector with two matching candidates that differ on an axis it doesn't
   read will pick wrong eventually.** Example: matching a browser by account,
   when the same account was logged in on two machines. Find the axis that
   actually decides it and read it.

10. **Uncommitted files may belong to a live parallel session.** Check mtime, check
    whether a second `git status` shows the set growing, and check
    `git log --all -S<symbol>` before you commit, stash or delete anything you
    didn't write.

11. **Staleness reports go stale in both directions.** A list of "N things out of
    date" computed yesterday is wrong today. Re-run the check before acting on
    a report.

12. **A failed headless or automated call burns its retry budget.** Don't retry
    blindly in a loop. Find out why it failed (auth, a limit, a missing
    dependency), fix that, then run it once.
