# [PROJECT_NAME]

> [One sentence: what this project does.]

## Stack

- **Runtime:** <!-- Node 20, Python 3.12, etc. -->
- **Framework:** <!-- Next.js 14, FastAPI, etc. -->
- **Key deps:** <!-- Prisma, Redis, etc. -->
- **Test:** <!-- pnpm test, pytest, etc. -->
- **Format:** <!-- prettier --write, ruff format . (mirrors PROJECT_FMT in settings.json env) -->
- **Build:** <!-- pnpm build, cargo build --release -->
- **Deploy:** <!-- fly deploy, vercel --prod -->

## Canary

Every completed task must end with: `[Canary:PROJECT_NAME:TASK_NAME]`
Can't produce it = context dropped. Stop and say so.

## Tooling

- **RTK** — Bash output auto-compressed. Use `rtk <cmd>` on high-output commands.
- **ctx7** — `npx ctx7 library <name> <query>` before touching any external API. Never rely on training data for library APIs.
- **Caveman** — `/caveman` for long sessions. `/caveman off` to disable.
- **Handoff** — use `/handoff` before ending a session, not `/compact`.

## Context rules

- Flag before any phase that risks one context window.
- Running low → `/checkpoint`, then stop. SessionStart hook will surface it.
- All commands must work headless.

## Error protocol

- **Minor** (typo, wrong flag): note inline, continue.
- **Major** (wrong architecture, repeated mistake):
  1. Append to `.claude/errors.md`
  2. If pattern → create `.claude/skills/<name>.md`
  3. If approach changes → append to **Learned rules** below

## Agents

Ask before spawning. Defined in `.claude/agents/`.
`ReadOnly` · `BuildValidator` · `LogAnalyzer` · `Researcher` · `CodeReviewer` · `DocWriter`

## Folder map

Each major dir has a `CLAUDE.md`. Read it first.

<!-- src/ — app logic | infra/ — do not edit generated files -->

## Scoped rules

`.claude/rules/` files load by glob match. Add per-project.

<!-- api.md → src/api/** | db.md → src/db/** -->

## Learned rules

<!-- Claude appends here on major errors. Do not delete. -->
