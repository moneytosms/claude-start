#!/bin/bash
# Claude Code statusLine command. Receives session JSON on stdin.
# Line 1: model | dir | git branch(dirty)
# Line 2: context %, duration, lines +/-

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
DIRNAME="${DIR##*/}"

BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
DIRTY=""
if [ -n "$BRANCH" ] && [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
  DIRTY="*"
fi

RESET='\033[0m'
DIM='\033[2m'
CYAN='\033[36m'
MAGENTA='\033[35m'

if [ "$PCT" -ge 80 ]; then CTX_COLOR='\033[31m'
elif [ "$PCT" -ge 50 ]; then CTX_COLOR='\033[33m'
else CTX_COLOR='\033[32m'
fi

DURATION_S=$((DURATION_MS / 1000))
DURATION="${DURATION_S}s"
if [ "$DURATION_S" -ge 60 ]; then
  DURATION="$((DURATION_S / 60))m$((DURATION_S % 60))s"
fi

LINE1="${CYAN}[$MODEL]${RESET} ${DIRNAME}"
if [ -n "$BRANCH" ]; then
  LINE1="$LINE1 ${MAGENTA}${BRANCH}${DIRTY}${RESET}"
fi

LINE2="${CTX_COLOR}${PCT}% ctx${RESET} ${DIM}|${RESET} ${DURATION} ${DIM}|${RESET} +${ADDED}/-${REMOVED}"

echo -e "$LINE1"
echo -e "$LINE2"
