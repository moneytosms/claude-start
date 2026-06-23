# install.ps1 — claude-template bootstrap (Windows native PowerShell)
# Run once after cloning. Idempotent where possible.
# Prerequisites: git, node 18+, cargo (Rust), claude (Claude Code CLI)
#
# Usage: .\install.ps1

$ErrorActionPreference = "Continue"  # Don't stop on non-critical errors

function Write-Info  { param($msg) Write-Host "[claude-template] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[warn] $msg" -ForegroundColor Yellow }
function Write-Fatal { param($msg) Write-Host "[error] $msg" -ForegroundColor Red; exit 1 }

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
Write-Info "Checking prerequisites..."
if (-not (Get-Command git   -ErrorAction SilentlyContinue)) { Write-Fatal "git not found. Install from https://git-scm.com" }
if (-not (Get-Command node  -ErrorAction SilentlyContinue)) { Write-Fatal "node not found. Install Node.js 18+ from https://nodejs.org" }
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) { Write-Fatal "cargo not found. Install Rust from https://rustup.rs" }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Write-Fatal "claude not found. Install Claude Code CLI and authenticate." }

$nodeVer = [int](node -e "process.stdout.write(process.versions.node.split('.')[0])")
if ($nodeVer -lt 18) { Write-Fatal "Node.js 18+ required. Found $(node --version). Upgrade: https://nodejs.org" }
Write-Info "Prerequisites OK  node=$(node --version)  cargo=$(cargo --version)"

# ── 2. RTK — Rust Token Killer ────────────────────────────────────────────────
Write-Info "Installing RTK..."
if (Get-Command rtk -ErrorAction SilentlyContinue) {
  Write-Info "RTK already installed. Skipping."
} else {
  try {
    cargo install --git https://github.com/rtk-ai/rtk
    Write-Info "RTK installed."
  } catch {
    Write-Warn "RTK install failed. Install manually: cargo install --git https://github.com/rtk-ai/rtk"
  }
}
try { rtk init -g } catch { Write-Warn "rtk init -g failed — run manually. Verify with: rtk gain" }

# ── 3. addyosmani/agent-skills ────────────────────────────────────────────────
Write-Info "Installing addyosmani/agent-skills..."
try { claude plugin marketplace add addyosmani/agent-skills }
catch { Write-Warn "Failed — install manually: claude plugin marketplace add addyosmani/agent-skills" }

# ── 4. Caveman ────────────────────────────────────────────────────────────────
Write-Info "Installing Caveman..."
try { claude plugin marketplace add JuliusBrussee/caveman }
catch { Write-Warn "Failed — install manually: claude plugin marketplace add JuliusBrussee/caveman" }

# ── 5. Ponytail ───────────────────────────────────────────────────────────────
Write-Info "Installing Ponytail..."
try { claude plugin marketplace add DietrichGebert/ponytail }
catch { Write-Warn "Failed — install manually: claude plugin marketplace add DietrichGebert/ponytail" }

# ── 6. mattpocock/skills ──────────────────────────────────────────────────────
Write-Info "Installing mattpocock/skills..."
try { npx --yes skills@latest add mattpocock/skills }
catch { Write-Warn "Failed — run manually: npx skills@latest add mattpocock/skills" }
# Select: grill-me, handoff, tdd, git-guardrails-claude-code, write-a-skill

# ── 7. Hooks note (Windows) ───────────────────────────────────────────────────
Write-Warn "Hooks are .sh scripts. On Windows they run via WSL or Git Bash."
Write-Warn "After install, open WSL and run: chmod +x .claude/hooks/*.sh"

# ── 8. Copy global CLAUDE.md template ────────────────────────────────────────
$globalDir = "$env:USERPROFILE\.claude"
$globalMd  = "$globalDir\CLAUDE.md"
if (Test-Path $globalMd) {
  Write-Info "Global CLAUDE.md already exists. Skipping."
} else {
  New-Item -ItemType Directory -Force -Path $globalDir | Out-Null
  Copy-Item "CLAUDE.md" $globalMd
  Write-Info "Global CLAUDE.md created at $globalMd"
}

# ── 9. Copy settings.local.json template ─────────────────────────────────────
$localSettings = ".claude\settings.local.json"
if (-not (Test-Path $localSettings)) {
  Copy-Item ".claude\settings.local.json.example" $localSettings
  Write-Info "Created .claude\settings.local.json from example."
}

# ── 10. Remove template .git ──────────────────────────────────────────────────
Write-Info "Removing template git history..."
Remove-Item -Recurse -Force ".git"

# ── 11. Fresh git repo ────────────────────────────────────────────────────────
Write-Info "Initializing fresh git repository..."
git init
git add .
git commit -m "init: claude-template bootstrap"
Write-Info "Bootstrap commit created."

# ── 12. Hand off to Claude ────────────────────────────────────────────────────
Write-Info ""
Write-Info "All done. Handing off to Claude..."
Write-Info ""

$prompt = @"
Read CLAUDE.md and .claude/settings.json. Then:
1. Ask me: project name, one-sentence description, stack (language, framework, key deps), test command, format command, build command, deploy command, and a canary codename.
2. Fill in all placeholders in CLAUDE.md with my answers.
3. Update .claude/settings.local.json: set PROJECT_FMT to my format command.
4. Update .claude/settings.json env.PROJECT_FMT to the same formatter.
5. Create .claude/rules/ files for any major dirs (src/, infra/, etc).
6. Write a CLAUDE.md stub in each major dir.
7. Confirm what was set up and what still needs manual input.
"@
claude $prompt
