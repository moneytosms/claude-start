# install-existing.ps1 — adopt claude-template into an existing repo (Windows native PowerShell)
# Non-destructive to git: never touches .git. Backs up any existing .claude/ before overwriting.
#
# Usage: .\install-existing.ps1 -Target C:\path\to\existing\project

param(
  [Parameter(Mandatory = $true)]
  [string]$Target
)

$ErrorActionPreference = "Stop"

function Write-Info  { param($msg) Write-Host "[claude-template] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[warn] $msg" -ForegroundColor Yellow }
function Write-Fatal { param($msg) Write-Host "[error] $msg" -ForegroundColor Red; exit 1 }

$TemplateDir = $PSScriptRoot
if (-not (Test-Path $Target)) { Write-Fatal "Target dir not found: $Target" }
$Target = (Resolve-Path $Target).Path

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Fatal "claude not found. Install Claude Code CLI and authenticate."
}

Write-Info "Adopting claude-template into: $Target"

# ── 1. Back up existing .claude/, then replace wholesale with the template ───
$BackupDir = $null
$targetClaude = "$Target\.claude"
if (Test-Path $targetClaude) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $BackupDir = "$Target\.claude.backup-$stamp"
  Move-Item $targetClaude $BackupDir
  Write-Info "Existing .claude\ backed up to $(Split-Path $BackupDir -Leaf)"
}
New-Item -ItemType Directory -Force -Path $targetClaude | Out-Null
$gitAvailable = Get-Command git -ErrorAction SilentlyContinue
$isRepo = $false
if ($gitAvailable) {
  Push-Location $TemplateDir
  git rev-parse --is-inside-work-tree *> $null
  $isRepo = ($LASTEXITCODE -eq 0)
  Pop-Location
}
if ($isRepo) {
  # Only copy git-tracked files -- skips local cruft like bash.log
  Push-Location $TemplateDir
  $trackedFiles = git ls-files .claude
  Pop-Location
  foreach ($f in $trackedFiles) {
    $src = Join-Path $TemplateDir $f
    $dest = Join-Path $Target $f
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item $src $dest -Force
  }
} else {
  Copy-Item "$TemplateDir\.claude\*" $targetClaude -Recurse -Force
}
Write-Info "Template .claude\ written."

# ── 2. .mcp.json — back up if present, then write template's ─────────────────
$templateMcp = "$TemplateDir\.mcp.json"
$targetMcp = "$Target\.mcp.json"
if (Test-Path $templateMcp) {
  if (Test-Path $targetMcp) {
    Copy-Item $targetMcp "$targetMcp.backup"
    Write-Info ".mcp.json backed up to .mcp.json.backup"
  }
  Copy-Item $templateMcp $targetMcp -Force
}

# ── 3. settings.local.json from example ───────────────────────────────────────
$localSettings = "$Target\.claude\settings.local.json"
$localExample  = "$Target\.claude\settings.local.json.example"
if ((-not (Test-Path $localSettings)) -and (Test-Path $localExample)) {
  Copy-Item $localExample $localSettings
  Write-Info "Created .claude\settings.local.json from example."
}

# ── 4. Hooks note (Windows) ───────────────────────────────────────────────────
if (Test-Path "$Target\.claude\hooks") {
  Write-Warn "Hooks are .sh scripts. On Windows they run via WSL or Git Bash."
  Write-Warn "After install, open WSL and run: chmod +x .claude/hooks/*.sh"
}

# ── 5. Global CLAUDE.md — only if missing ─────────────────────────────────────
$globalDir = "$env:USERPROFILE\.claude"
$globalMd  = "$globalDir\CLAUDE.md"
if (-not (Test-Path $globalMd)) {
  New-Item -ItemType Directory -Force -Path $globalDir | Out-Null
  Copy-Item "$TemplateDir\CLAUDE.md" $globalMd
  Write-Info "Global CLAUDE.md created at $globalMd"
}

# ── 6. Hand off to Claude: merge CLAUDE.md + reconcile .claude/ backup ───────
$templateMd = "$TemplateDir\CLAUDE.md"
$targetMd = "$Target\CLAUDE.md"

if (-not (Test-Path $targetMd)) {
  Copy-Item $templateMd $targetMd
  Write-Info "No existing CLAUDE.md — copied template as starting point."
}

Write-Info "Handing off to Claude to merge CLAUDE.md and reconcile .claude\ backup..."
$refPath = "$Target\.claude\.template-claude-md-reference.md"
Copy-Item $templateMd $refPath

$backupNote = ""
if ($BackupDir) {
  $backupLeaf = Split-Path $BackupDir -Leaf
  $backupNote = @"


Your OLD .claude/ directory (before this install) was backed up to ./$backupLeaf. It has just been replaced by the template's .claude/ (hooks, agents, commands, rules).
Compare the two: check ./$backupLeaf for anything project-specific you had -- custom hooks, custom agents, custom commands, custom rules/*.md, non-default settings.json permissions/hooks -- and port anything still relevant into the new ./.claude/, merging rather than blind-overwriting the template's files. Skip anything that's clearly generic template boilerplate you never touched. When done, delete ./$backupLeaf.
"@
}

$prompt = @"
I've just adopted the claude-start template into this existing project.

My existing CLAUDE.md at ./CLAUDE.md is the BASE -- do not replace or restructure it, do not change its voice or existing content.
The template's CLAUDE.md is at ./.claude/.template-claude-md-reference.md for reference only.

Task 1 -- merge CLAUDE.md:
- Add to MY CLAUDE.md whatever useful sections/knowledge the template has that mine is missing -- e.g. Canary convention, Tooling (RTK/ctx7/hooks), Context rules, Error protocol, Agents list -- but adapt each to reference the actual tools and structure now present in .claude/ (agents, commands, hooks) rather than pasting placeholders.
- Do not duplicate sections that already exist in mine in some form -- merge/extend instead.
- Do not touch Stack/Test/Lint/Build/Deploy placeholders unless mine are empty and the template has a real value to offer (it usually won't).
- When done, delete ./.claude/.template-claude-md-reference.md.
$backupNote

Task 2 -- set up RTK wrappers for this project's actual stack:
- Detect the stack from repo files (package.json -> npm/pnpm, requirements.txt/pyproject.toml -> pip/ruff/pytest/mypy, Cargo.toml -> cargo, go.mod -> go/golangci-lint, Gemfile -> rake/rubocop/rspec, pom.xml/build.gradle -> mvn/gradlew, *.csproj -> dotnet, next.config.* -> next, schema.prisma -> prisma, playwright.config.* -> playwright, jest.config.*/vitest.config.* -> jest/vitest).
- Run 'rtk help' to confirm exact subcommand names before writing them.
- Fill the 'RTK wrappers' line under ## Stack in MY CLAUDE.md with the real commands for what's actually present, replacing the placeholder -- not the generic example list.

Task 3 -- print a short summary of everything added, merged, or ported, and everything deleted.
"@

Push-Location $Target
claude $prompt
Pop-Location

Write-Info ""
Write-Info "Done. .git was not touched. Review the diff, then commit when ready."
