#!/usr/bin/env bash
# install-upstream.sh: install a curated list of third-party skills/agents/rules from UPSTREAM.
#
# Safety properties:
#   - Refuses to run until ~/.claude/.curated-approved exists (create it once you, or your
#     org's review process, have approved selection.txt; put the reference inside).
#   - Dry run by default. --apply copies files.
#   - Only `git clone` and file copies. Nothing from any cloned repo is executed:
#     no install scripts, no hooks, no package managers.
#   - Records repo, resolved commit SHA, licence line and every copied path in
#     ~/.claude/vendor-src/PROVENANCE.md, so what came from where is never a question.
#   - Flags copied markdown that references scripts it would need (not copied).
#
# Usage: bash install-upstream.sh [--apply] [selection.txt]

set -euo pipefail

APPLY=0
SEL=""
for a in "$@"; do
  case "$a" in
    --apply) APPLY=1 ;;
    *) SEL="$a" ;;
  esac
done
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEL="${SEL:-$here/selection.txt}"
CLAUDE="$HOME/.claude"
SRC="$CLAUDE/vendor-src"
PROV="$SRC/PROVENANCE.md"

if [ ! -s "$CLAUDE/.curated-approved" ]; then
  echo "Refusing: $CLAUDE/.curated-approved is missing or empty."
  echo "After reviewing selection.txt, run:  echo '<who approved, date>' > $CLAUDE/.curated-approved"
  exit 2
fi
command -v git >/dev/null || { echo "git not found"; exit 2; }

mkdir -p "$SRC" "$CLAUDE/skills" "$CLAUDE/agents" "$CLAUDE/rules-library"
[ "$APPLY" = 1 ] && { [ -f "$PROV" ] || printf '# Upstream provenance\n\nApproval: %s\n\n' "$(cat "$CLAUDE/.curated-approved")" > "$PROV"; }

declare -A FETCHED
fetch() {  # $1 owner/repo  $2 ref  -> echoes local dir
  local repo="$1" ref="$2" dir="$SRC/${1//\//__}"
  if [ -z "${FETCHED[$repo]:-}" ]; then
    if [ ! -d "$dir/.git" ]; then
      GIT_TERMINAL_PROMPT=0 timeout 300 git clone --quiet --filter=blob:none "https://github.com/$repo.git" "$dir" >&2
    fi
    if [ "$ref" != "HEAD" ]; then
      git -C "$dir" -c advice.detachedHead=false checkout --quiet "$ref" >&2
    fi
    FETCHED[$repo]=1
    if [ "$APPLY" = 1 ]; then
      local sha lic
      sha="$(git -C "$dir" rev-parse HEAD)"
      lic="$(head -n 1 "$dir"/LICENSE* 2>/dev/null | head -n 1 || true)"
      printf '## %s\n- commit: %s\n- licence: %s\n- fetched: %s\n' "$repo" "$sha" "${lic:-NOT FOUND, check by hand}" "$(date -u +%FT%TZ)" >> "$PROV"
    fi
  fi
  echo "$dir"
}

copied=0; missing=0
while read -r repo ref kind name _; do
  [ -z "${repo:-}" ] && continue
  case "$repo" in \#*) continue ;; esac
  dir="$(fetch "$repo" "$ref")"
  case "$kind" in
    skill)      src="$(find "$dir" -type f -name SKILL.md -path "*/$name/SKILL.md" -not -path '*/.git/*' | head -n 1)"; src="${src%/SKILL.md}"; dest="$CLAUDE/skills/$name" ;;
    skill-root) src="$dir"; [ -f "$dir/SKILL.md" ] || src=""; dest="$CLAUDE/skills/$name" ;;
    agent)      src="$(find "$dir" -type f -name "$name.md" -path '*agents*' -not -path '*/.git/*' | head -n 1)"; dest="$CLAUDE/agents/$name.md" ;;
    rules)      src="$(find "$dir" -type d -path "*rules/$name" -not -path '*/.git/*' | head -n 1)"; dest="$CLAUDE/rules-library/$name" ;;
    *) echo "  ? unknown kind '$kind' for $name"; continue ;;
  esac
  if [ -z "$src" ] || [ ! -e "$src" ]; then
    echo "  MISSING  $kind $name in $repo"; missing=$((missing+1)); continue
  fi
  refs="$(grep -rlE '(node|python3?|bash) [^ ]*scripts/|\./scripts/' "$src" 2>/dev/null | head -n 3 || true)"
  echo "  $( [ "$APPLY" = 1 ] && echo COPY || echo WOULD ) $kind $name  <-  ${src#$SRC/}"
  [ -n "$refs" ] && echo "           note: references scripts that were NOT copied: $(echo $refs | tr '\n' ' ')"
  if [ "$APPLY" = 1 ]; then
    rm -rf "$dest"
    if [ -d "$src" ]; then
      mkdir -p "$dest"
      (cd "$src" && tar --exclude=.git --exclude='*.sh' --exclude='*.js' --exclude='*.py' --exclude='bin' -cf - .) | (cd "$dest" && tar -xf -)
    else
      cp "$src" "$dest"
    fi
    printf -- '- %s %s -> %s\n' "$kind" "$name" "${dest#$HOME/}" >> "$PROV"
  fi
  copied=$((copied+1))
done < "$SEL"

echo
echo "$( [ "$APPLY" = 1 ] && echo Copied || echo 'Would copy' ): $copied | missing: $missing"
[ "$APPLY" = 1 ] && echo "Provenance: $PROV" || echo "Dry run. Re-run with --apply to install."
