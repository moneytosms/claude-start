# claude-start

Opinionated Claude Code starter. Clone, run the install script, answer five questions, start building.

## What you get

| Category        | What's included                                                                                                                                             |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Memory**      | `CLAUDE.md` with canary, error protocol, context rules — committed, teammates see the same thing                                                            |
| **Token tools** | RTK (89% avg CLI output compression) · Caveman (70% response compression) · ctx7 (live library docs)                                                        |
| **Skills**      | addyosmani/agent-skills (24 lifecycle skills) · mattpocock/skills (grill-me, handoff, tdd, git-guardrails, write-a-skill) · Ponytail (anti-overengineering) |
| **Hooks**       | session-start · notify · log-bash · pre-deploy-guard (lint + test gate) · auto-format · keep-going                                                          |
| **Commands**    | `/commit` `/pr` `/ship` `/plan` `/checkpoint` `/batch` `/review` `/verify`                                                                                  |
| **Agents**      | ReadOnly · BuildValidator · LogAnalyzer · Researcher · CodeReviewer · DocWriter                                                                             |
| **Logs**        | Decision log · error log · bash audit trail · checkpoint system                                                                                             |

## How it works day-to-day

### Opening a session

The `session-start` hook fires automatically. It sets your terminal tab title to the current git branch and surfaces any in-progress checkpoint so you start oriented without re-reading context.

### During a task

- **Before anything non-trivial:** `/plan` — scaffolds `Goal / Constraints / Acceptance Criteria / Unresolved Questions` in `.claude/plans/`
- **Unfamiliar library:** Claude uses `npx ctx7 library <name> <query>` before writing any API calls — never guesses from training data
- **Files are formatted on every write** — the `auto-format` hook runs `PROJECT_FMT` in the background, invisible
- **All bash commands are logged** to `.claude/bash.log` — full audit trail, no effort required
- **Context getting long:** `/caveman` halves output verbosity. Before stopping: `/checkpoint` saves exact state

### Finishing a task

- Every completed task ends with `[Canary:PROJECT_NAME:TASK_NAME]` — the `keep-going` hook checks for it and nudges Claude to continue if it's missing
- `/handoff` instead of `/compact` — precise surgical session doc, not lossy compression

### Shipping

```
/ship
```

That's it. Runs lint → build → test → commits → opens a PR. Stops at the first failure.

Or deploy directly — `pre-deploy-guard` intercepts the deploy command and runs your lint and test suite first. Blocks with a reason if anything fails.

### Code review

```
/review
```

Invokes the `CodeReviewer` agent on your current diff. Returns a structured report with severity-tagged issues. You decide what to act on.

### Working with teammates

Commit `.claude/` — your teammates get the same hooks, agents, and commands automatically. They run through `ONBOARDING.md` to set up their local settings and understand what everything does.

## Requirements

- Node.js 18+
- Rust + Cargo (for RTK)
- Claude Code installed and authenticated
- `git`, `gh` (GitHub CLI) for `/commit`, `/pr`, `/ship`

## Install

**macOS / Linux / WSL:**

```bash
git clone https://github.com/moneytosms/claude-start my-project
cd my-project
chmod +x install.sh && ./install.sh
```

**Windows:**

```powershell
git clone https://github.com/moneytosms/claude-start my-project
cd my-project
.\install.ps1
```

The script installs all tooling, wipes the template git history, inits a fresh repo, then opens Claude to ask you five questions: project name, description, runtime, formatter, and canary codename. That's the only interactive step.

## After install

1. **Fill in the rest of `CLAUDE.md`** as the project takes shape — Test, Lint, Build, Deploy commands
2. **Create `.claude/rules/`** files as major directories emerge — see `rules/example.md` for the format
3. **Teammates:** run through `ONBOARDING.md` to get their local settings configured
4. **Run `/ponytail-audit`** once the codebase has real code — finds complexity to cut
5. **Check `rtk gain`** after a few sessions — shows your actual token savings

## What's not included

- **MCP servers** — add to `.mcp.json` (team-shared, committed) or `settings.local.json` (personal)
- **CI/CD** — `/ship` handles local → remote; pipeline config is project-specific
- **Issue tracker** — add mattpocock's triage skills if needed
