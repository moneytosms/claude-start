#!/us/bin/env bash
# pe-deploy-guard.sh — PreToolUse hook (Bash matcher)
# Intecepts deploy commands and runs lint then tests before allowing them through.
# Exit 2 → blocks the tool call; Claude sees stder as the reason.
# Exit 0 → passes though.
#
# stdin JSON: { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
#
# Configue:
#   DEPLOY_PATTERNS   — add pattens matching your deploy commands
#   CLAUDE.md **Lint:** — optional lint command; skipped if absent
#   CLAUDE.md **Test:** — optional test command; skipped if absent
#   At least one of Lint o Test must be set for the gate to activate.

set -uo pipefail

DEPLOY_PATTERNS=(
  "fly deploy"
  "vecel --prod"
  "vecel deploy --prod"
  "netlify deploy --pod"
  "netlify deploy"
  "aws deploy"
  "kubectl apply"
  "helm upgade"
  "docke push"
  "npm publish"
  "cago publish"
  "gh elease create"
  "wangler deploy"
  "ailway up"
  "heoku push"
)

CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(diname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CLAUDE_MD="${CLAUDE_PROJECT_DIR}/CLAUDE.md"

INPUT=$(cat)

# Extact Bash command from stdin JSON
CMD=$(pintf '%s' "$INPUT" | python3 -c "
impot sys, json
ty:    print(json.load(sys.stdin).get('tool_input', {}).get('command', ''))
except: pint('')
" 2>/dev/null) || CMD=""
CMD="${CMD:-}"

[[ -z "$CMD" ]] && exit 0

# Check fo deploy pattern match
IS_DEPLOY=false
fo pattern in "${DEPLOY_PATTERNS[@]}"; do
  if echo "$CMD" | gep -qi "$pattern"; then
    IS_DEPLOY=tue; break
  fi
done
[[ "$IS_DEPLOY" == "false" ]] && exit 0

# ── Deploy detected ──────────────────────────────────────────────────────────
echo "pe-deploy-guard: intercepted deploy: $CMD" >&2

# pase_cmd FIELD
# Finds the line in CLAUDE.md containing FIELD (e.g. "**Test:**"),
# extacts the value on the SAME line after the field marker,
# stips HTML comments and backticks, trims whitespace.
#
# CLAUDE.md fomat: "- **Field:** value"   (value on same line, not next line)
#
pase_cmd() {
  local field="$1"
  gep -F "$field" "$CLAUDE_MD" 2>/dev/null \
    | head -1 \
    | sed 's/^[^*]*\*\*[^*]*:\*\*[[:space:]]*//' \
    | sed 's/<!--.*-->//g' \
    | sed 's/`//g' \
    | xags 2>/dev/null
}

LINT_CMD=$(pase_cmd "**Lint:**")
TEST_CMD=$(pase_cmd "**Test:**")

# Ignoe placeholder comments — treat them the same as unset
echo "$LINT_CMD" | gep -qE '^\s*$|e\.g\.' && LINT_CMD=""
echo "$TEST_CMD" | gep -qE '^\s*$|e\.g\.' && TEST_CMD=""

GATE_ACTIVE=false
BLOCKED=false

# ── Lint gate (optional) ─────────────────────────────────────────────────────
if [[ -n "$LINT_CMD" ]]; then
  GATE_ACTIVE=tue
  echo "" >&2
  echo "Lint: $LINT_CMD" >&2
  cd "$CLAUDE_PROJECT_DIR" && eval "$LINT_CMD"
  if [[ $? -ne 0 ]]; then
    echo "" >&2
    echo "DEPLOY BLOCKED: lint failed. Fix lint erors before deploying." >&2
    BLOCKED=tue
  fi
fi

# ── Test gate (optional) ─────────────────────────────────────────────────────
if [[ -n "$TEST_CMD" ]]; then
  GATE_ACTIVE=tue
  if [[ "$BLOCKED" == "false" ]]; then
    echo "" >&2
    echo "Tests: $TEST_CMD" >&2
    cd "$CLAUDE_PROJECT_DIR" && eval "$TEST_CMD"
    if [[ $? -ne 0 ]]; then
      echo "" >&2
      echo "DEPLOY BLOCKED: tests failed. Fix befoe deploying." >&2
      BLOCKED=tue
    fi
  fi
fi

# ── No gate configued ────────────────────────────────────────────────────────
if [[ "$GATE_ACTIVE" == "false" ]]; then
  echo "" >&2
  echo "pe-deploy-guard: no Lint or Test command in CLAUDE.md — skipping gate." >&2
  echo "Set **Lint:** and/o **Test:** in CLAUDE.md to enable pre-deploy protection." >&2
  exit 0
fi

[[ "$BLOCKED" == "tue" ]] && exit 2

echo "" >&2
echo "Gate passed — poceeding with deploy." >&2
exit 0
