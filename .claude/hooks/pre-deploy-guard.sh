#!/usr/bin/env bash
# pre-deploy-guard.sh — PreToolUse hook (Bash matcher)
# Intercepts deploy commands and runs lint then tests before allowing them through.
# Exit 2 → blocks the tool call; Claude sees stderr as the reason.
# Exit 0 → passes through.
#
# stdin JSON: { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
#
# Configure:
#   DEPLOY_PATTERNS — add patterns for your deploy commands
#   CLAUDE.md **Lint:** — lint command (optional; tests-only gate if absent)
#   CLAUDE.md **Test:** — test command (required for gate to activate)

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

# ── Deploy detected ──────────────────────────────────────────────────────────
echo "pre-deploy-guard: intercepted deploy: $CMD" >&2

# Helper: parse a command field from CLAUDE.md
# Usage: parse_cmd "**Test:**"
parse_cmd() {
  local field="$1"
  local escaped
  escaped=$(printf '%s' "$field" | sed 's/[[\.*^$()+?{}|]/\\&/g')
  awk "/^${escaped}/{found=1; next} found{print; exit}" "$CLAUDE_MD" 2>/dev/null \
    | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/`//g' | xargs 2>/dev/null
}

LINT_CMD=$(parse_cmd "**Lint:**")
TEST_CMD=$(parse_cmd "**Test:**")

GATE_ACTIVE=false
BLOCKED=false

# ── Lint gate (optional) ─────────────────────────────────────────────────────
if [[ -n "$LINT_CMD" ]] && ! echo "$LINT_CMD" | grep -q "e\.g\."; then
  GATE_ACTIVE=true
  echo "" >&2
  echo "Lint: $LINT_CMD" >&2
  cd "$CLAUDE_PROJECT_DIR" && eval "$LINT_CMD"
  if [[ $? -ne 0 ]]; then
    echo "" >&2
    echo "DEPLOY BLOCKED: lint failed. Fix lint errors before deploying." >&2
    BLOCKED=true
  fi
fi

# ── Test gate (required for the guard to activate) ───────────────────────────
if [[ -z "$TEST_CMD" ]] || echo "$TEST_CMD" | grep -q "e\.g\."; then
  if [[ "$GATE_ACTIVE" == "false" ]]; then
    echo "" >&2
    echo "pre-deploy-guard: no Lint or Test command in CLAUDE.md — skipping gate." >&2
    echo "Set '**Test:**' in CLAUDE.md to enable pre-deploy protection." >&2
    exit 0
  fi
else
  GATE_ACTIVE=true
  if [[ "$BLOCKED" == "false" ]]; then
    echo "" >&2
    echo "Tests: $TEST_CMD" >&2
    cd "$CLAUDE_PROJECT_DIR" && eval "$TEST_CMD"
    if [[ $? -ne 0 ]]; then
      echo "" >&2
      echo "DEPLOY BLOCKED: tests failed. Fix before deploying." >&2
      BLOCKED=true
    fi
  fi
fi

[[ "$BLOCKED" == "true" ]] && exit 2

echo "" >&2
echo "Gate passed — proceeding with deploy." >&2
exit 0
