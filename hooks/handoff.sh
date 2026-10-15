#!/usr/bin/env bash
# handoff.sh: SessionEnd / PreCompact hook. Writes ~/.claude/handoffs/<slug>.md with
# the session's last user goals and git state, so a crashed or compacted session can
# resume without re-exploring (pair: skills/resume-handoff).
#
# Design rules, each learned the hard way:
#   - Bounded read: only the transcript TAIL, never the whole file.
#   - temp file + verify the body + rename. A handoff with no body is a failure, not a
#     success, and must never replace a good one.
#   - Local only. Never commits, never pushes, never touches the network.
# Needs: jq, git. Exit 0 always, so a broken handoff never blocks the session.

set -uo pipefail

payload="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

transcript="$(jq -r '.transcript_path // empty' <<<"$payload")"
cwd="$(jq -r '.cwd // empty' <<<"$payload")"
session="$(jq -r '.session_id // "unknown"' <<<"$payload")"
event="$(jq -r '.hook_event_name // "hook"' <<<"$payload")"
[ -n "$cwd" ] || cwd="$PWD"

slug="$(printf '%s' "$cwd" | sed 's#[/.]#-#g; s#^-##')"
out_dir="$HOME/.claude/handoffs"
mkdir -p "$out_dir"
out="$out_dir/$slug.md"
tmp="$(mktemp "$out_dir/.$slug.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

goals=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  goals="$(tail -n 600 "$transcript" | jq -r '
      select(.type == "user")
      | .message.content
      | if type == "string" then .
        else (map(select(.type == "text") | .text) | join(" "))
        end
      | select(length > 0)
      | gsub("\\s+"; " ")
      | ltrimstr(" ")
      | .[0:300]' 2>/dev/null | grep -vE '^(<|Base directory for this skill)' | tail -n 5 | sed 's/^/- /')"
fi

git_state="(not a git repo)"
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null)"
  last="$(git -C "$cwd" log -1 --format='%h %s' 2>/dev/null)"
  ahead="$(git -C "$cwd" rev-list --count '@{u}..HEAD' 2>/dev/null || echo '?')"
  dirty="$(git -C "$cwd" status --porcelain 2>/dev/null | head -n 20)"
  git_state="branch: ${branch:-detached} | unpushed: $ahead | last: $last
dirty:
${dirty:-  (clean)}"
fi

{
  echo "# Handoff: $cwd"
  echo
  echo "- written: $(date -u +%FT%TZ) ($event)"
  echo "- session: $session"
  echo
  echo "## Git"
  echo '```'
  echo "$git_state"
  echo '```'
  echo
  echo "## Last user messages"
  echo "${goals:-- (none found)}"
} > "$tmp"

# Verify the body before replacing anything: no user messages AND no git = useless.
if [ -z "$goals" ] && [ "$git_state" = "(not a git repo)" ]; then
  exit 0
fi
mv "$tmp" "$out"
trap - EXIT
exit 0
