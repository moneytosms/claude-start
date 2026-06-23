#!/usr/bin/env bash
# session-start.sh — SessionStart hook
# Fires when a session opens (new, resume, clear, or compact).
# stdout from this hook is added as context Claude can read before the first prompt.
# Claude Code passes JSON via stdin: { "source": "startup"|"resume"|"clear"|"compact", ... }

set -uo pipefail

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CHECKPOINT="${CLAUDE_PROJECT_DIR}/.claude/checkpoint.md"
BASH_LOG="${CLAUDE_PROJECT_DIR}/.claude/bash.log"

INPUT=$(cat)

# Extract source (how session started)
SOURCE=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try: print(json.load(sys.stdin).get('source','startup'))
except: print('startup')
" 2>/dev/null || echo "startup")

# Surface checkpoint if in-progress
if [[ -f "$CHECKPOINT" ]] && grep -q "Status: in-progress" "$CHECKPOINT" 2>/dev/null; then
  echo "=== CHECKPOINT (in-progress) ==="
  cat "$CHECKPOINT"
  echo "================================="
  echo ""
fi

# Surface last bash command for orientation (on resume/startup only)
if [[ "$SOURCE" != "clear" ]] && [[ -f "$BASH_LOG" ]] && [[ -s "$BASH_LOG" ]]; then
  LAST_CMD=$(grep -v '^#' "$BASH_LOG" 2>/dev/null | tail -1)
  if [[ -n "$LAST_CMD" ]]; then
    echo "Last command: $LAST_CMD"
  fi
fi

exit 0
