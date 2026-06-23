# claude-template — Setup Spec

This repo is a cloneable Claude Code starter. After cloning, run the install script for your platform. The script handles all tooling, then deletes `.git` and hands off to Claude to configure the project for your specific stack.

---

## Repo Structure

```
claude-template/
├── README.md
├── install.sh                  # Unix/macOS/WSL
├── install.ps1                 # Windows native
├── CLAUDE.md                   # Project-level template (edit after init)
├── .gitignore
└── .claude/
    ├── settings.json           # Committed — shared config, hooks registry, permissions
    ├── settings.local.json     # Gitignored — machine-specific overrides
    ├── agents/
    │   ├── ReadOnly.md
    │   ├── BuildValidator.md
    │   ├── LogAnalyzer.md
    │   ├── Researcher.md
    │   ├── CodeReviewer.md
    │   └── DocWriter.md
    ├── commands/
    │   ├── commit.md
    │   ├── pr.md
    │   ├── ship.md
    │   ├── plan.md
    │   ├── checkpoint.md
    │   ├── batch.md
    │   └── verify.md           # Placeholder — fill in per project
    ├── hooks/
    │   ├── session-start.sh
    │   ├── log-bash.sh
    │   ├── pre-deploy-guard.sh
    │   ├── auto-format.sh
    │   └── keep-going.sh
    ├── output-styles/
    │   ├── terse.md            # Default
    │   └── explain.md
    ├── rules/                  # Glob-scoped rules — add per project
    │   └── .gitkeep
    ├── skills/                 # Populated by install script + mattpocock npx
    │   └── .gitkeep
    ├── errors.md               # Major error log — Claude appends
    ├── decisions.md            # Architecture decision log — DocWriter maintains
    ├── bash.log                # Bash audit trail — log-bash.sh appends
    └── checkpoint.md           # Session state — Claude writes, SessionStart reads
```

---

## Install Scripts

Both scripts do the same things in order, then hand off to Claude.

### What both scripts do

1. **Check prerequisites** — git, node, cargo (Rust). Warn and exit if missing.
2. **Install RTK** — `cargo install --git https://github.com/rtk-ai/rtk` then `rtk init -g`
3. **Install addyosmani/agent-skills** — `claude plugin marketplace add addyosmani/agent-skills`
4. **Install Caveman** — `claude plugin marketplace add JuliusBrussee/caveman`
5. **Install Ponytail** — `claude plugin marketplace add DietrichGebert/ponytail`
6. **Install mattpocock/skills** — `npx skills@latest add mattpocock/skills` in non-interactive mode, selecting: `grill-me`, `handoff`, `tdd`, `git-guardrails-claude-code`, `write-a-skill`
7. **Make hooks executable** — `chmod +x .claude/hooks/*.sh` (install.sh only)
8. **Copy global CLAUDE.md** — copy `~/.claude/CLAUDE.md` template if not already present
9. **Remove `.git`** — `rm -rf .git` (install.sh) / `Remove-Item -Recurse -Force .git` (install.ps1). Project is now clean, no upstream.
10. **Init fresh git repo** — `git init && git add . && git commit -m "init: claude-template bootstrap"`
11. **Hand off to Claude** — `claude` with an init prompt (see below)

### Claude init prompt (end of install)

```
claude "Read CLAUDE.md and .claude/settings.json. Then:
1. Ask me: project name, one-sentence description, stack (language, framework, key deps), test command, format command, build command, deploy command, and a canary codename.
2. Fill in all placeholders in CLAUDE.md with my answers.
3. Update settings.local.json with PROJECT_FMT set to my format command.
4. Create .claude/rules/ files for any major dirs that exist (src/, infra/, etc).
5. Write a folder-level CLAUDE.md stub in each major dir.
6. Confirm what was set up and what still needs manual input."
```

This is the only interactive step. Everything before it is deterministic.

---

## Token Tooling

### RTK — Rust Token Killer
`github.com/rtk-ai/rtk` — Rust binary, Apache 2.0
Intercepts every Bash tool call and compresses output before it hits context. 89% avg noise reduction across git, test runners, find, grep. Installs its own PreToolUse hook into `settings.json` via `rtk init -g`. Install script handles this — verify with `rtk gain` after first session.

Only affects Bash calls. Claude's native Read/Glob tools bypass it.

### Context7 — CLI (preferred over MCP)
`npx ctx7 library <name> <query>` or `npx ctx7 docs <id> <query>`
Pulls version-accurate library docs on demand. CLI is strictly better than MCP for Claude Code: no upfront config, works mid-session, pipeable, can be invoked from hooks or commands. MCP requires `settings.json` registration before the session starts and can't be added dynamically.

Use before implementing anything that touches an external library API. Don't let Claude guess from training data.

```bash
npx ctx7 library react "server components"
npx ctx7 docs /vercel/next.js "middleware"
```

---

## Skills

### addyosmani/agent-skills
`/plugin marketplace add addyosmani/agent-skills`
24 lifecycle skills, auto-activate based on task context. High-value subset:
- `spec-driven-development` — spec before any code
- `planning-and-task-breakdown` — atomic task decomposition
- `debugging-and-error-recovery` — root cause before fix, no guess-and-check
- `code-review-and-quality` — gate before merge
- `code-simplification` — complexity reduction on demand
- `security-and-hardening` — threat surface review

### mattpocock/skills
`npx skills@latest add mattpocock/skills` — copies SKILL.md files into `.claude/skills/`. No plugin.
Install script runs this non-interactively. Selected skills:

- **`grill-me`** — relentless pre-task questioning until all ambiguity is resolved. Run before any non-trivial feature. Closes the alignment gap before code is written, not after.
- **`handoff`** — surgical session transition doc: what was done, decisions made, exact in-progress state, next step. Use this instead of `/compact`. `/compact` is lossy; handoff is precise.
- **`tdd`** — enforces test-first. Write failing test → implement → pass. Prevents Claude skipping straight to code.
- **`git-guardrails-claude-code`** — PreToolUse hook blocking `push --force`, `reset --hard`, `clean -fd`. Self-registers into `settings.json`. Set and forget.
- **`write-a-skill`** — scaffolds new skills with correct structure (progressive disclosure, bundled resources, proper description). Use when creating custom skills.

### Caveman
`/plugin marketplace add JuliusBrussee/caveman`
Strips all prose from Claude's output — no narration, no preamble, just signal. ~65-75% output token reduction. Persistent via flag file. Also has `caveman-compress` sub-skill that rewrites CLAUDE.md into compressed form — run once on any bloated memory file, saves tokens on every future session load.
- `/caveman` to activate, `/caveman off` to disable
- `/caveman-compress` to compress a memory file

### Ponytail
`/plugin marketplace add DietrichGebert/ponytail`
Anti-overengineering skill. Teaches Claude to prefer stdlib, native elements, one-liners. ~54% less code measured on real agentic tasks. Activate per project, not globally.
- `/ponytail-review` — diff-level complexity audit, returns delete-list
- `/ponytail-audit` — whole-repo scan, ranked list of what to cut or replace
- `/ponytail-debt` — harvests `ponytail:` comments into a deferred work ledger

---

## Hooks

All in `.claude/hooks/`. Registered in `settings.json`. Install script makes them executable.

### `session-start.sh` — SessionStart
On session open: check for `.claude/checkpoint.md`, print contents if found. Echo last line of `bash.log` for orientation. Claude starts every session knowing where it left off.

### `log-bash.sh` — PreToolUse
Append every Bash command + ISO timestamp to `.claude/bash.log`. Passive, non-blocking. Full audit trail of what actually ran.

### `pre-deploy-guard.sh` — PreToolUse
Intercepts any deploy command (configurable pattern match). Runs lint + test suite first. Blocks with reason if anything fails. Only passes through on green. Prevents broken code hitting production. **Most important hook in this setup.**

### `auto-format.sh` — PostToolUse
After any file write: run `$PROJECT_FMT` on the changed file only. Set in `settings.local.json`. No-ops if unset. Keeps formatting invisible and automatic.

### `keep-going.sh` — Stop
When Claude emits a stop mid-task: send a continue nudge. Only fires when canary line is absent from last output (task incomplete). Doesn't fire on clean task completion.

**Auto-registered by install:**
- RTK's PreToolUse hook — via `rtk init -g`
- `git-guardrails-claude-code` — via mattpocock skills install

---

## Slash Commands

All in `.claude/commands/`. Deterministic — same input, same steps, every time.

### `/commit`
Stage all → generate concise imperative commit msg from diff → commit → push via `gh`.

### `/pr`
Read commits since branch split from main → generate PR title + body → `gh pr create`. Opens editor for final review.

### `/ship`
lint → build → test → `/commit` → `/pr`. Stops on first failure. Requires clean working tree.

### `/plan`
Scaffold `.claude/plans/YYYY-MM-DD-<name>.md` with Goal / Constraints / AC / Unresolved Questions pre-filled from context given.

### `/checkpoint`
Write current state to `.claude/checkpoint.md` (status / in-progress / next step / blockers). Run before ending a session mid-task or when context is running low. SessionStart hook surfaces this on next open.

### `/batch`
Split a large task into parallelisable subtasks → spawn subagent per subtask (permission check first) → collect and merge. For big refactors or multi-file migrations.

### `/verify`
Project-specific verification suite. **Placeholder — fill in per repo.** E.g. E2E tests, type check, API contract validation, domain-specific checks.

---

## Agents

Defined in `.claude/agents/`. Each is an isolated context window — gets only what it needs, nothing more.

| Agent | Job | Tools | Model |
|---|---|---|---|
| `ReadOnly` | Safe codebase exploration, zero edits | Read | Haiku |
| `BuildValidator` | Run build + tests, return pass/fail + errors | Bash | Sonnet |
| `LogAnalyzer` | Parse crash logs, build errors, traces | Read, Bash | Haiku |
| `Researcher` | Web fetch + synthesis, return findings | WebFetch, WebSearch | Sonnet |
| `CodeReviewer` | Review diffs, return summary + issues | Read, Bash (read-only) | Sonnet |
| `DocWriter` | Documentation maintenance | Read, Write | Sonnet |

### DocWriter — detail
Invoke after significant architectural decisions or at end of a session. Jobs:
1. Walk all `CLAUDE.md` files in major dirs — flag stale entries (dead paths, wrong commands, outdated deps)
2. Append to `.claude/decisions.md` — decision made, alternatives considered, what was rejected and why
3. Append to `.claude/errors.md` on major mistakes — what, root cause, rule going forward
4. Summarize completed plan phases into the relevant `.claude/plans/<name>.md`

Review its writes before committing on first use. Don't run unsupervised until you trust the output.

---

## Output Styles

`.claude/output-styles/` — named modes. Set default in `settings.json`. Switch mid-session by naming the style.

### `terse.md` (default)
No preamble. Lead with answer. Code blocks for anything runnable. Explanations one line, non-obvious only. No post-action summary unless asked. No em dashes.

### `explain.md`
Full reasoning shown. Tradeoffs explained before deciding. Use during architecture sessions or when debugging something unfamiliar.

---

## Rules Directory

`.claude/rules/` — scoped markdown files that auto-load on glob match. Keep CLAUDE.md lean; put domain rules here.

Pattern: short, imperative, specific. What to do, what never to do, why in one line.

Example files (create as project grows):
- `api.md` → `src/api/**` — rate limiting rules, auth requirements, never log request bodies
- `db.md` → `src/db/**` — migration workflow, never raw queries in app code
- `infra.md` → `infra/**` — managed by Terraform, never edit generated files manually

Register globs in `settings.json` under `rules`.

---

## Structured Files

Pre-created by install script. Claude appends; humans review.

**`.claude/errors.md`**
```
## [YYYY-MM-DD] <title>
What: <what went wrong>
Why: <root cause>
Rule: <what to do differently going forward>
```

**`.claude/decisions.md`**
```
## [YYYY-MM-DD] <decision>
Context: <why this decision was needed>
Options: <what was considered>
Chosen: <what was picked>
Rejected: <what was dropped and why>
```

**`.claude/checkpoint.md`**
```
## Checkpoint [YYYY-MM-DD HH:MM]
Status: <done / in-progress / blocked>
In progress: <what's mid-flight>
Next step: <exact next action>
Blockers: <anything unresolved>
```

**`.claude/bash.log`** — append-only, written by `log-bash.sh`. Do not edit manually.

---

## `settings.json`

`.claude/settings.json` — committed, shared.
`.claude/settings.local.json` — gitignored, machine-specific.

```json
{
  "model": "claude-sonnet-4-6",
  "defaultOutputStyle": "terse",
  "statusline": {
    "show": ["model", "agent", "tokens_used", "git_branch"],
    "badges": ["caveman"]
  },
  "permissions": {
    "allow": [
      "Bash(rtk *)",
      "Bash(gh *)",
      "Bash(git status)",
      "Bash(git log *)",
      "Bash(git diff *)",
      "Bash(npx ctx7 *)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git reset --hard*)",
      "Bash(git clean *)",
      "Bash(rm -rf *)"
    ]
  },
  "hooks": {
    "SessionStart": [".claude/hooks/session-start.sh"],
    "PreToolUse": [
      ".claude/hooks/log-bash.sh",
      ".claude/hooks/pre-deploy-guard.sh"
    ],
    "PostToolUse": [".claude/hooks/auto-format.sh"],
    "Stop": [".claude/hooks/keep-going.sh"]
  },
  "rules": {}
}
```

`settings.local.json` (gitignored):
```json
{
  "env": {
    "PROJECT_FMT": "<your formatter command>",
    "LOCAL_PORT": "3000"
  }
}
```

---

## README.md (for the repo)

```markdown
# claude-template

Opinionated Claude Code starter. Clone, run install, answer a few questions, start building.

## What you get

- Global + project CLAUDE.md with canary, error protocol, context management
- RTK (Rust Token Killer) — 89% avg CLI output compression, auto-hooked
- Caveman — 65-75% output token reduction
- addyosmani/agent-skills — 24 lifecycle skills, auto-activate
- mattpocock/skills — grill-me, handoff, tdd, git-guardrails, write-a-skill
- Ponytail — anti-overengineering
- 5 hooks — session-start, log-bash, pre-deploy-guard, auto-format, keep-going
- 7 slash commands — commit, pr, ship, plan, checkpoint, batch, verify
- 6 subagents — ReadOnly, BuildValidator, LogAnalyzer, Researcher, CodeReviewer, DocWriter
- Structured decision log, error log, bash audit trail, checkpoint system
- settings.json with statusline, permissions, hook registry

## Requirements

- Node.js 18+
- Rust + Cargo (for RTK)
- Claude Code installed and authenticated

## Install

**macOS / Linux / WSL:**
```bash
git clone https://github.com/<you>/claude-template my-project
cd my-project
chmod +x install.sh && ./install.sh
```

**Windows:**
```powershell
git clone https://github.com/<you>/claude-template my-project
cd my-project
.\install.ps1
```

The script installs all tooling, removes `.git`, inits a fresh repo, then launches Claude to configure the project for your stack. The Claude init step is the only interactive part — it asks for project name, stack, commands, and a canary codename, then fills in all placeholders.

## After install

- Set `PROJECT_FMT` in `.claude/settings.local.json` if the init didn't catch it
- Add `.claude/rules/` files as your project dirs take shape
- Run `/ponytail-audit` once the codebase has some code in it
- Run `rtk gain` after a few sessions to verify token savings

## What's not included

- MCP servers — add your own to `settings.json` based on your stack
- CI/CD — `/ship` handles local → remote, pipeline config is project-specific
- Issue tracker integration — not included by default, add mattpocock's triage skills if needed
```

---

## Install Order (what the scripts implement)

1. Check prerequisites (node, cargo). Exit with instructions if missing.
2. `cargo install --git https://github.com/rtk-ai/rtk && rtk init -g`
3. `claude plugin marketplace add addyosmani/agent-skills`
4. `claude plugin marketplace add JuliusBrussee/caveman`
5. `claude plugin marketplace add DietrichGebert/ponytail`
6. `npx skills@latest add mattpocock/skills` (non-interactive: grill-me, handoff, tdd, git-guardrails-claude-code, write-a-skill)
7. `chmod +x .claude/hooks/*.sh` (install.sh only)
8. Copy `~/.claude/CLAUDE.md` global template if not present
9. `rm -rf .git` / `Remove-Item -Recurse -Force .git`
10. `git init && git add . && git commit -m "init: claude-template bootstrap"`
11. Launch Claude with init prompt