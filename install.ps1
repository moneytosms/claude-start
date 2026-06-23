# install.ps1 — claude-template bootstrap (Windows native PowerShell)
# Run once after cloning. Idempotent where possible.
# Prerequisites: git, node 18+, cargo (Rust), claude (Claude Code CLI)
#
# Usage: .\install.ps1

# Stop on unhandled terminating errors; external command failures checked via $LASTEXITCODE
$ErrorActionPreference = "Stop"

function Write-Info  { param($msg) Write-Host "[claude-template] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[warn] $msg" -ForegroundColor Yellow }
function Write-Fatal { param($msg) Write-Host "[error] $msg" -ForegroundColor Red; exit 1 }

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
Write-Info "Checking prerequisites..."
if (-not (Get-Command git    -ErrorAction SilentlyContinue)) { Write-Fatal "git not found. Install from https://git-scm.com" }
if (-not (Get-Command node   -ErrorAction SilentlyContinue)) { Write-Fatal "node not found. Install Node.js 18+ from https://nodejs.org" }
if (-not (Get-Command cargo  -ErrorAction SilentlyContinue)) { Write-Fatal "cargo not found. Install Rust from https://rustup.rs" }
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { Write-Fatal "claude not found. Install Claude Code CLI and authenticate." }

$nodeVer = [int](node -e "process.stdout.write(process.versions.node.split('.')[0])")
if ($nodeVer -lt 18) { Write-Fatal "Node.js 18+ required. Found $(node --version). Upgrade: https://nodejs.org" }
Write-Info "Prerequisites OK  node=$(node --version)  cargo=$(cargo --version)"

# ── 2. RTK — Rust Token Killer ────────────────────────────────────────────────
Write-Info "Installing RTK..."
if (Get-Command rtk -ErrorAction SilentlyContinue) {
  Write-Info "RTK already installed. Skipping."
} else {
  # $ErrorActionPreference = Stop means we need to handle non-terminating external failures via $LASTEXITCODE
  $ErrorActionPreference = "Continue"
  cargo install --git https://github.com/rtk-ai/rtk
  if ($LASTEXITCODE -ne 0) {
    Write-Warn "RTK install failed. Install manually: cargo install --git https://github.com/rtk-ai/rtk"
  } else {
    Write-Info "RTK installed."
  }
  $ErrorActionPreference = "Stop"
}

$ErrorActionPreference = "Continue"
rtk init -g 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Warn "rtk init -g failed — run manually. Verify with: rtk gain"
}
$ErrorActionPreference = "Stop"

# ── 3. addyosmani/agent-skills ────────────────────────────────────────────────
Write-Info "Installing addyosmani/agent-skills..."
$ErrorActionPreference = "Continue"
claude plugin marketplace add addyosmani/agent-skills
if ($LASTEXITCODE -ne 0) {
  Write-Warn "Failed — install manually: claude plugin marketplace add addyosmani/agent-skills"
}
$ErrorActionPreference = "Stop"

# ── 4. Caveman ────────────────────────────────────────────────────────────────
Write-Info "Installing Caveman..."
$ErrorActionPreference = "Continue"
claude plugin marketplace add JuliusBrussee/caveman
if ($LASTEXITCODE -ne 0) {
  Write-Warn "Failed — install manually: claude plugin marketplace add JuliusBrussee/caveman"
}
$ErrorActionPreference = "Stop"

# ── 5. Ponytail ───────────────────────────────────────────────────────────────
Write-Info "Installing Ponytail..."
$ErrorActionPreference = "Continue"
claude plugin marketplace add DietrichGebert/ponytail
if ($LASTEXITCODE -ne 0) {
  Write-Warn "Failed — install manually: claude plugin marketplace add DietrichGebert/ponytail"
}
$ErrorActionPreference = "Stop"

# ── 6. mattpocock/skills ──────────────────────────────────────────────────────
Write-Info "Installing mattpocock/skills..."
# Select: grill-me, handoff, tdd, git-guardrails-claude-code, write-a-skill
$ErrorActionPreference = "Continue"
npx --yes skills@latest add mattpocock/skills
if ($LASTEXITCODE -ne 0) {
  Write-Warn "Failed — run manually: npx skills@latest add mattpocock/skills"
}
$ErrorActionPreference = "Stop"

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
Bootstrap complete. The template is ready but nothing about your project is configured yet.

Ask me the following questions one at a time, wait for my answer before moving on:
1. What is the project name?
2. One sentence: what does it do?
3. What is your primary language and runtime? (e.g. TypeScript / Node 22)
4. What formatter should run on every file save? (e.g. prettier --write, ruff format -- or 'none')
5. What is your canary codename? (short, memorable word used at the end of every completed task)

Once I've answered all five:
- Fill in the placeholders in CLAUDE.md (name, description, runtime, format command, canary).
- Set PROJECT_FMT in .claude/settings.local.json to the format command. If none, leave it empty.
- Leave Stack, Test, Lint, Build, and Deploy as placeholders -- I'll fill those in when the project takes shape.
- Print a single confirmation block showing what was set and what's still a placeholder.

Do not scaffold directories, create stubs, or make assumptions about the project structure. The codebase does not exist yet.
"@
claude $prompt
