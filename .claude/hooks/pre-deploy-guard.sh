#!/usr/bin/env bash
# pre-deploy-guard.sh — PreToolUse hook (Bash matcher)
# Intercepts deploy commands and runs the test suite before allowing them.
# Exit 2 → blocks the tool call (Claude sees stderr as the reason).
# Exit 0 → passes through.
#
# stdin JSON: { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
# Add project-specific deploy patterns to DEPLOY_PATTERNS.

set -uo pipefail

DEPLOY_PATTERNS=(
  "fly deploy"
  "vercel --prod"
  "vercel deploy --prod"
  "netlify deploy --prod"
  "netlify deploy"
  "aws deploy"
  "kubectl apply"
  "helm upgrade"
  "docker push"
  "npm publish"
  "cargo publish"
  "gh release create"
  "wrangler deploy"
  "railway up"
  "heroku push"
)

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CLAUDE_MD="${CLAUDE_PROJECT_DIR}/CLAUDE.md"

INPUT=$(cat)

# Extract Bash command from stdin JSON
CMD=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:    print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
except: print('')
" 2>/dev/null) || CMD=""
CMD="${CMD:-}"

[[ -z "$CMD" ]] && exit 0

# Check for deploy pattern match
IS_DEPLOY=false
for pattern in "${DEPLOY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qi "$pattern"; then
    IS_DEPLOY=true; break
  fi
done
[[ "$IS_DEPLOY" == "false" ]] && exit 0

# --- Deploy detected ---
echo "pre-deploy-guard: deploy command intercepted: $CMD" >&2
echo "" >&2

# Parse test command from CLAUDE.md (line after **Test:**)
TEST_CMD=$(awk '/^\*\*Test:\*\*/{found=1; next} found{print; exit}' "$CLAUDE_MD" 2>/dev/null \
  | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/`//g' | xargs 2>/dev/null)

if [[ -z "$TEST_CMD" ]] || echo "$TEST_CMD" | grep -q "e\.g\."; then
  echo "pre-deploy-guard: no test command in CLAUDE.md — skipping gate." >&2
  echo "Set '**Test:**' in CLAUDE.md to enable pre-deploy protection." >&2
  exit 0
fi

echo "Running: $TEST_CMD" >&2
cd "$CLAUDE_PROJECT_DIR" && eval "$TEST_CMD"
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "" >&2
  echo "DEPLOY BLOCKED: tests failed (exit $EXIT_CODE). Fix before deploying." >&2
  exit 2  # exit 2 = blocking error: Claude sees stderr, tool call is prevented
fi

echo "Tests passed — proceeding with deploy." >&2
exit 0
