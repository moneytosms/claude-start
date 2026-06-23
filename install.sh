#!/usr/bin/env bash
# install.sh — claude-template bootstrap (macOS / Linux / WSL)
# Run once after cloning. Idempotent where possible.
# Prerequisites: git, node 18+, cargo (Rust), claude (Claude Code CLI)

set -uo pipefail

RED='\033[0;31m'; YLW='\033[1;33m'; GRN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GRN}[claude-template]${NC} $*"; }
warn()  { echo -e "${YLW}[warn]${NC} $*"; }
die()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
info "Checking prerequisites..."
command -v git    >/dev/null 2>&1 || die "git not found. Install git and re-run."
command -v node   >/dev/null 2>&1 || die "node not found. Install Node.js 18+ from https://nodejs.org"
command -v cargo  >/dev/null 2>&1 || die "cargo not found. Install Rust from https://rustup.rs"
command -v claude >/dev/null 2>&1 || die "claude not found. Install Claude Code CLI and authenticate."

NODE_VER=$(node -e "process.stdout.write(process.versions.node.split('.')[0])")
(( NODE_VER >= 18 )) || die "Node.js 18+ required. Found $(node --version). Upgrade: https://nodejs.org"
info "Prerequisites OK  node=$(node --version)  cargo=$(cargo --version | cut -d' ' -f2)"

# ── 2. RTK — Rust Token Killer ────────────────────────────────────────────────
info "Installing RTK..."
if command -v rtk >/dev/null 2>&1; then
  info "RTK already installed. Skipping."
else
  cargo install --git https://github.com/rtk-ai/rtk \
    || warn "RTK install failed. Install manually: cargo install --git https://github.com/rtk-ai/rtk"
fi
rtk init -g 2>/dev/null || warn "rtk init -g failed — run manually. Verify with: rtk gain"

# ── 3. addyosmani/agent-skills ────────────────────────────────────────────────
info "Installing addyosmani/agent-skills..."
claude plugin marketplace add addyosmani/agent-skills \
  || warn "addyosmani/agent-skills failed — install manually: claude plugin marketplace add addyosmani/agent-skills"

# ── 4. Caveman ────────────────────────────────────────────────────────────────
info "Installing Caveman..."
claude plugin marketplace add JuliusBrussee/caveman \
  || warn "Caveman failed — install manually: claude plugin marketplace add JuliusBrussee/caveman"

# ── 5. Ponytail ───────────────────────────────────────────────────────────────
info "Installing Ponytail..."
claude plugin marketplace add DietrichGebert/ponytail \
  || warn "Ponytail failed — install manually: claude plugin marketplace add DietrichGebert/ponytail"

# ── 6. mattpocock/skills ──────────────────────────────────────────────────────
info "Installing mattpocock/skills..."
# Try non-interactive first, fall back to interactive
npx --yes skills@latest add mattpocock/skills \
  || warn "mattpocock/skills failed — run manually: npx skills@latest add mattpocock/skills"
# Select: grill-me, handoff, tdd, git-guardrails-claude-code, write-a-skill

# ── 7. Make hooks executable ──────────────────────────────────────────────────
info "Making hooks executable..."
chmod +x .claude/hooks/*.sh

# ── 8. Copy global CLAUDE.md template ────────────────────────────────────────
GLOBAL_MD="$HOME/.claude/CLAUDE.md"
if [[ -f "$GLOBAL_MD" ]]; then
  info "Global CLAUDE.md already exists. Skipping."
else
  mkdir -p "$HOME/.claude"
  cp CLAUDE.md "$GLOBAL_MD"
  info "Global CLAUDE.md created at $GLOBAL_MD"
fi

# ── 9. Copy settings.local.json template ─────────────────────────────────────
if [[ ! -f ".claude/settings.local.json" ]]; then
  cp .claude/settings.local.json.example .claude/settings.local.json
  info "Created .claude/settings.local.json from example."
fi

# ── 10. Remove template .git ──────────────────────────────────────────────────
info "Removing template git history..."
rm -rf .git

# ── 11. Fresh git repo ────────────────────────────────────────────────────────
info "Initializing fresh git repository..."
git init
git add .
git commit -m "init: claude-template bootstrap"
info "Bootstrap commit created."

# ── 12. Hand off to Claude ────────────────────────────────────────────────────
info ""
info "All done. Handing off to Claude..."
info ""

claude "Read CLAUDE.md and .claude/settings.json. Then:
1. Ask me: project name, one-sentence description, stack (language, framework, key deps), test command, format command, build command, deploy command, and a canary codename.
2. Fill in all placeholders in CLAUDE.md with my answers.
3. Update .claude/settings.local.json: set PROJECT_FMT to my format command.
4. Update .claude/settings.json env.PROJECT_FMT to the same formatter.
5. Create .claude/rules/ files for any major dirs (src/, infra/, etc).
6. Write a CLAUDE.md stub in each major dir.
7. Confirm what was set up and what still needs manual input."
