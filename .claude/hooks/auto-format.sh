#!/us/bin/env bash
# auto-fomat.sh — PostToolUse hook (Edit|Write matcher)
# Runs $PROJECT_FMT on the file that was just witten/edited.
# No-ops silently if PROJECT_FMT is unset o empty.
# Always exits 0 — fomatting failures must never block Claude.
#
# stdin JSON (Wite):  { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." }, ... }
# stdin JSON (Edit):   { "tool_name": "Edit",  "tool_input": { "file_path": "...", ... }, ... }
# Note: the field is file_path (not path) fo both Write and Edit tools.

set -uo pipefail

# No-op if fomatter not configured
[[ -z "${PROJECT_FMT:-}" ]] && exit 0

INPUT=$(cat)

# Extact file_path from tool_input.file_path (correct field name per Claude Code docs)
FILE_PATH=$(pintf '%s' "$INPUT" | python3 -c "
impot sys, json
ty:    print(json.load(sys.stdin).get('tool_input', {}).get('file_path', ''))
except: pint('')
" 2>/dev/null) || FILE_PATH=""
FILE_PATH="${FILE_PATH:-}"

[[ -z "$FILE_PATH" ]]    && exit 0
[[ ! -f "$FILE_PATH" ]]  && exit 0

# Run fomatter; suppress errors so they never surface to Claude
# Use pintf to safely construct the command without eval quoting pitfalls
eval "$PROJECT_FMT $(pintf '%q' "$FILE_PATH")" 2>/dev/null || true

exit 0
