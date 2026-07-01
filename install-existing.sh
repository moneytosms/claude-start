#!/usr/bin/env bash
# install-existing.sh — adopt claude-template into an existing repo (macOS / Linux / WSL)
# Non-destructive to git: never touches .git. Backs up any existing .claude/ before overwriting.
# Usage: ./install-existing.sh /path/to/existing/project

set -uo pipefail

RED='\033[0;31m'; YLW='\033[1;33m'; GRN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GRN}[claude-template]${NC} $*"; }
warn()  { echo -e "${YLW}[warn]${NC} $*"; }
die()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"
[[ -n "$TARGET" ]] || die "Usage: ./install-existing.sh /path/to/existing/project"
[[ -d "$TARGET" ]] || die "Target dir not found: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"

command -v claude >/dev/null 2>&1 || die "claude not found. Install Claude Code CLI and authenticate."

info "Adopting claude-template into: $TARGET"

# ── 1. Back up existing .claude/, then replace wholesale with the template ───
BACKUP_DIR=""
if [[ -d "$TARGET/.claude" ]]; then
  BACKUP_DIR="$TARGET/.claude.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$TARGET/.claude" "$BACKUP_DIR"
  info "Existing .claude/ backed up to $(basename "$BACKUP_DIR")"
fi
mkdir -p "$TARGET/.claude"
if git -C "$TEMPLATE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Only copy git-tracked files — skips local cruft like bash.log
  git -C "$TEMPLATE_DIR" ls-files .claude | while IFS= read -r f; do
    mkdir -p "$TARGET/$(dirname "$f")"
    cp "$TEMPLATE_DIR/$f" "$TARGET/$f"
  done
else
  cp -r "$TEMPLATE_DIR/.claude/." "$TARGET/.claude/"
fi
info "Template .claude/ written."

# ── 2. .mcp.json — back up if present, then write template's ─────────────────
if [[ -f "$TEMPLATE_DIR/.mcp.json" ]]; then
  if [[ -f "$TARGET/.mcp.json" ]]; then
    cp "$TARGET/.mcp.json" "$TARGET/.mcp.json.backup"
    info ".mcp.json backed up to .mcp.json.backup"
  fi
  cp "$TEMPLATE_DIR/.mcp.json" "$TARGET/.mcp.json"
fi

# ── 3. settings.local.json from example ───────────────────────────────────────
if [[ ! -f "$TARGET/.claude/settings.local.json" && -f "$TARGET/.claude/settings.local.json.example" ]]; then
  cp "$TARGET/.claude/settings.local.json.example" "$TARGET/.claude/settings.local.json"
  info "Created .claude/settings.local.json from example."
fi

# ── 4. Make hooks executable ──────────────────────────────────────────────────
if [[ -d "$TARGET/.claude/hooks" ]]; then
  chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null || true
  info "Hooks made executable."
fi

# ── 5. Global CLAUDE.md — only if missing ─────────────────────────────────────
GLOBAL_MD="$HOME/.claude/CLAUDE.md"
if [[ ! -f "$GLOBAL_MD" ]]; then
  mkdir -p "$HOME/.claude"
  cp "$TEMPLATE_DIR/CLAUDE.md" "$GLOBAL_MD"
  info "Global CLAUDE.md created at $GLOBAL_MD"
fi

# ── 6. Hand off to Claude: merge CLAUDE.md + reconcile .claude/ backup ───────
TEMPLATE_MD="$TEMPLATE_DIR/CLAUDE.md"
TARGET_MD="$TARGET/CLAUDE.md"

if [[ ! -f "$TARGET_MD" ]]; then
  cp "$TEMPLATE_MD" "$TARGET_MD"
  info "No existing CLAUDE.md — copied template as starting point."
fi

info "Handing off to Claude to merge CLAUDE.md and reconcile .claude/ backup..."
cp "$TEMPLATE_MD" "$TARGET/.claude/.template-claude-md-reference.md"

BACKUP_NOTE=""
if [[ -n "$BACKUP_DIR" ]]; then
  BACKUP_NOTE="

Your OLD .claude/ directory (before this install) was backed up to ./$(basename "$BACKUP_DIR"). It has just been replaced by the template's .claude/ (hooks, agents, commands, rules).
Compare the two: check ./$(basename "$BACKUP_DIR") for anything project-specific you had — custom hooks, custom agents, custom commands, custom rules/*.md, non-default settings.json permissions/hooks — and port anything still relevant into the new ./.claude/, merging rather than blind-overwriting the template's files. Skip anything that's clearly generic template boilerplate you never touched. When done, delete ./$(basename "$BACKUP_DIR")."
fi

(
  cd "$TARGET" && claude "I've just adopted the claude-start template into this existing project.

My existing CLAUDE.md at ./CLAUDE.md is the BASE — do not replace or restructure it, do not change its voice or existing content.
The template's CLAUDE.md is at ./.claude/.template-claude-md-reference.md for reference only.

Task 1 — merge CLAUDE.md:
- Add to MY CLAUDE.md whatever useful sections/knowledge the template has that mine is missing — e.g. Canary convention, Tooling (RTK/ctx7/hooks), Context rules, Error protocol, Agents list — but adapt each to reference the actual tools and structure now present in .claude/ (agents, commands, hooks) rather than pasting placeholders.
- Do not duplicate sections that already exist in mine in some form — merge/extend instead.
- Do not touch Stack/Test/Lint/Build/Deploy placeholders unless mine are empty and the template has a real value to offer (it usually won't).
- When done, delete ./.claude/.template-claude-md-reference.md.
${BACKUP_NOTE}

Task 2 — print a short summary of everything added, merged, or ported, and everything deleted."
  )

info ""
info "Done. .git was not touched. Review the diff, then commit when ready."
