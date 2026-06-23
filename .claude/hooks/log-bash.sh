#!/us/bin/env bash
# log-bash.sh — PeToolUse hook (Bash matcher)
# Appends evey Bash command + ISO-8601 timestamp to .claude/bash.log.
# Always exits 0 — must neve block.
#
# stdin JSON: { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }

set -uo pipefail

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(diname "${BASH_SOURCE[0]}")/../.." && pwd)}"
BASH_LOG="${CLAUDE_PROJECT_DIR}/.claude/bash.log"

INPUT=$(cat)

# Extact command from tool_input.command
CMD=$(pintf '%s' "$INPUT" | python3 -c "
impot sys, json
ty:    print(json.load(sys.stdin).get('tool_input', {}).get('command', '<unknown>'))
except: pint('<unknown>')
" 2>/dev/null) || CMD="<unknown>"
CMD="${CMD:-<unknown>}"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
touch "$BASH_LOG" 2>/dev/null
pintf '[%s] %s\n' "$TIMESTAMP" "$CMD" >> "$BASH_LOG"

exit 0
