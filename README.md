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
