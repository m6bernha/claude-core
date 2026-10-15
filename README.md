# claude-core

Process skills, one documentation agent and a crash-safe handoff hook for
[Claude Code](https://docs.claude.com/en/docs/claude-code). Plain markdown plus one
shell hook. No MCP servers, no network calls, no telemetry.

## Install

Inside Claude Code:

```
/plugin marketplace add m6bernha/claude-core
/plugin install claude-core@claude-core
```

The handoff hook needs `jq` and `git` on `PATH` (`sudo apt install jq` / `brew install jq`).

## What's included

### Skills

| Skill | Use it when |
|---|---|
| `census-then-build` | A change is repo-wide ("everywhere we do X"). Builds a line-level inventory of every affected site before any edit, then works the inventory. |
| `session-log` | Ending a session or nearing context limits. Writes a short handoff to `~/.claude/session-logs/`. |
| `resume-handoff` | "Continue where we left off" after a crash, a usage limit or compaction. Reads the hook's handoff and checks it against live git. |
| `sitrep-lite` | End of day in shared repos. Read-only status across repos plus a daily note. Never commits, pushes, merges or prunes. |
| `research-bridge` | Several research agents just finished. Dedupe, map findings to actions, and produce a ranked TODO with done-when criteria. |
| `parallel-chat-manifest` | Spawning or closing a parallel session. A small manifest carries results back to the parent. |
| `audit-github-repo` | Before installing any third-party repo, package, plugin or extension: where data goes, what code runs, how far to trust the supply chain. |

### Agent

- `doc-updater`: generated docs (codemaps, API references) and authored prose
  (guides, READMEs) in one agent, language-agnostic.

### Hooks

- `hooks/handoff.sh` runs on **SessionEnd** and **PreCompact** (auto-enabled by
  the plugin). It writes `~/.claude/handoffs/<cwd-slug>.md` with the last few
  user messages and the git state. It reads only the transcript tail, writes to
  a temp file, verifies the body, then renames. It never touches the network.
- `hooks/optional/model-triage.js` (opt-in) is a UserPromptSubmit nudge about
  which model tier a prompt needs. To enable it, add it to `~/.claude/settings.json`:
  ```json
  { "hooks": { "UserPromptSubmit": [ { "hooks": [ { "type": "command",
    "command": "node /path/to/claude-core/hooks/optional/model-triage.js" } ] } ] } }
  ```

### Docs

- `docs/CONVENTIONS.md`: working conventions to import from your `CLAUDE.md`
  (`@path/to/CONVENTIONS.md`). Git safety in shared repos, decisions before
  mechanisms, verified-done, writing style, delegation.
- `docs/LESSONS.md`: twelve generic engineering lessons about hooks, jobs,
  config rendering and pipelines.
- `examples/settings.example.json`: a deny-first permissions block (no push, PR
  or force operations; no reading credential files or `.env`).

### Curated upstream installer

`curated/selection.txt` lists third-party skills and agents worth having
(Anthropic-adjacent and community repos). `curated/install-upstream.sh` clones
each one **from its own upstream**, copies only the markdown, executes nothing
from the cloned repos, and records repo, commit and licence in
`~/.claude/vendor-src/PROVENANCE.md`.

```bash
# review selection.txt, delete what you don't want, then record your approval:
echo "reviewed by <you>, $(date +%F)" > ~/.claude/.curated-approved
bash curated/install-upstream.sh          # dry run
bash curated/install-upstream.sh --apply
```

## License

MIT. See `LICENSE`. `agents/doc-updater.md` adapts two MIT-licensed works; see
`THIRD_PARTY_NOTICES.md`.
