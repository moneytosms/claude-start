# [PROJECT_NAME]

> [One sentence: what this project is and what it does.]

## Stack
- **Language/Runtime:** <!-- e.g. Python 3.12, Node 20 -->
- **Framework:** <!-- e.g. FastAPI, Next.js 14 -->
- **Key deps:** <!-- e.g. Prisma, Redis, SQLAlchemy -->
- **Test:** <!-- e.g. `pytest`, `pnpm test` -->
- **Format:** <!-- e.g. `ruff format .`, `prettier --write` — mirrors $PROJECT_FMT in settings.local.json -->
- **Build:** <!-- e.g. `pnpm build`, `cargo build --release` -->
- **Deploy:** <!-- e.g. `fly deploy`, `vercel --prod` -->

## Canary
End every completed task with exactly: `[Canary:PROJECT_NAME:TASK_NAME]`
Can't produce it = context dropped. Stop and say so immediately.

## Token & Context Tools
- **RTK** active — Bash calls auto-compressed. Use `rtk <cmd>` explicitly on high-output commands (git log, test runners, find).
- **ctx7** for library docs — `npx ctx7 library <name> <query>` before implementing anything touching an external API. Never rely on training data for library behavior.
- **Caveman** — activate with `/caveman` for long sessions to cut output verbosity ~70%.
- **Handoff** — use `/handoff` over `/compact` before ending a session. Surgical, not lossy.

## Context Management
- Flag before starting any phase that risks exceeding one context window.
- Running low mid-task → run `/checkpoint`, then stop cleanly. SessionStart hook surfaces it next session.
- No GUI assumptions. All commands must work headless/SSH.

## Error Protocol
- **Minor** (syntax, wrong flag, typo): note inline, continue.
- **Major** (wrong architecture, repeated mistake, misread requirement):
  1. Append to `.claude/errors.md` — what / why / rule going forward
  2. If reusable pattern → create `.claude/skills/<name>.md`
  3. If changes overall approach → append to `## Learned Rules` below

## Plans
Use `/plan` to scaffold. Every plan: **Goal** / **Constraints** / **Acceptance Criteria** / **Unresolved Questions**

## Agents
Defined in `.claude/agents/`. Ask permission before spawning any. Available:
- `ReadOnly` — explore only, no edits
- `BuildValidator` — build + test, returns pass/fail
- `LogAnalyzer` — crash logs and traces
- `Researcher` — web fetch + synthesis
- `CodeReviewer` — diff review, no edits
- `DocWriter` — maintains decisions.md, errors.md, stale CLAUDE.md files

## Folder Map
Each major dir has a `CLAUDE.md`. Read it before exploring. Don't infer from filenames.
<!-- Fill in once structure is known -->
<!-- e.g. `src/` — app logic | `infra/` — Terraform, do not edit generated files -->

## Scoped Rules
`.claude/rules/` files auto-load by glob match (set in `settings.json`).
<!-- e.g. api.md → src/api/** | db.md → src/db/** | infra.md → infra/** -->

## Learned Rules
<!-- Claude appends here on major errors. Do not delete this section. -->