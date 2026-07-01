# CLAUDE.md — Root Template

> **How to use this file:** copy this to your repo root as `CLAUDE.md`, or merge it into an existing root `CLAUDE.md`. Fill in the `[ ]` blanks with your machine/environment specifics — nothing environment-specific ships in this template. Project- or directory-specific rules belong in `.claude/rules/*.md`, not here.

Extremely concise in all interactions and commit messages. Sacrifice grammar for concision.

## Environment

- OS: `[e.g. WSL2 Ubuntu 24.04 / macOS 15 / native Windows]`
- Shell: `[zsh / bash / pwsh]`
- Username: `[ ]`
- Path handling: `[note any cross-filesystem quirks, e.g. WSL <-> /mnt/c]`

## Engineering Philosophy

**Think before coding.** State assumptions explicitly; if uncertain, ask. If multiple interpretations exist, present them, don't pick silently. If something is unclear, stop and name what's confusing.

**Simplicity first.** Minimum code that solves the problem — nothing speculative. No abstractions for single-use code, no unrequested flexibility, no error handling for impossible scenarios. If it could be half the size, rewrite it.

**Surgical changes.** Touch only what the task requires. Don't refactor or reformat adjacent code. Match existing style even if you'd do it differently. Remove imports/vars that YOUR change orphaned; don't delete pre-existing dead code unless asked — mention it instead.

**Goal-driven execution.** Turn tasks into verifiable goals ("fix the bug" → "write a failing test, then make it pass"). For multi-step work, state a brief plan with a verification step per item, then loop independently against it.

## Reasoning

- Complex problem or needs max effort → ask: *"Elevate reasoning?"*
- Context window risk → stop immediately, give status, suggest next steps.
- IMPORTANT: never guess at library/API behavior. Use `ctx7` (below) instead.

## Plans

Every plan: **Goal** / **Constraints** / **Acceptance Criteria** / **Unresolved Questions**

## Verification

- IMPORTANT: if you can't verify it, don't ship it. Run the test/build/lint before declaring a task done — visual inspection isn't verification.
- Investigations ("investigate X") must be scoped narrowly or delegated to a subagent. Don't open-ended explore the whole repo.

## Secrets

- Never read `.env*` files or print secret values, even while debugging.
- Never commit anything matching a secret pattern (keys, tokens, passwords).

## Context Management

- When compacting, preserve: modified files list, test/build commands run, unresolved questions.
- Use `/btw` for quick factual side-questions that don't need to stay in context.
- Machine-specific overrides (ports, local paths, anything not fit for a shared file) → local/gitignored settings, not this file.

## Agents

- Ask permission before spawning. State what, why, expected output.
- Haiku for read-only/mechanical, Sonnet default, Opus for architecture only.
- Give subagents only the context they need, never a full project dump.
- Fork for breadth (scan/discover/summarize). Stay inline for depth (reasoning-heavy work you need to steer).

## Tools — prefer these over defaults

| Instead of | Use | Why |
|---|---|---|
| `grep` | `rg` | faster, respects .gitignore |
| `find` | `fd` | simpler syntax, faster |
| `cat` | `bat` | syntax highlighting, line numbers |
| `ls` | `eza` | richer output, git-aware |
| `cd` | `zoxide` (`z`) | frecency-based jump |
| `diff` | `delta` | readable side-by-side |
| `sed` | `sd` | simpler regex syntax |
| `du` | `dust` | visual, faster |
| `ps` | `procs` | readable, colorized |

GitHub/GitLab ops: `gh` / `glab` CLI only, never raw API calls.

## RTK — token-compressed command proxy

Use `rtk <subcommand>` instead of the raw tool whenever an RTK wrapper exists. It filters/compresses output before it hits context — same result, far fewer tokens.

Common wrappers: `rtk git`, `rtk gh`, `rtk find`, `rtk grep`, `rtk rg`, `rtk read`, `rtk tree`, `rtk ls`, `rtk diff`, `rtk log`, `rtk err` (run + show only errors), `rtk test` (run + show only failures), `rtk json`, `rtk deps`, `rtk env`.
Language/build tooling: `rtk npm`, `rtk pnpm`, `rtk cargo`, `rtk go`, `rtk pip`, `rtk tsc`, `rtk lint`, `rtk format`, `rtk pytest`, `rtk ruff`, `rtk mypy`, `rtk jest`, `rtk vitest`, `rtk playwright`, `rtk docker`, `rtk psql`.
No RTK wrapper exists → use the tool directly, don't force it.

## Docs

`npx ctx7 library <name> <query>` or `npx ctx7 docs <id> <query>` before touching any external library API. CLI over MCP: no config, works mid-session, pipeable.

## Git

- Branches: semantic, lowercase, hyphenated — `feat/auth-refresh`, `fix/login-crash`, `chore/update-deps`
- Commits: conventional commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`), imperative, ≤72 char subject, no period
- `gh` CLI for all GitHub ops

## Output

- Lead with the answer, no preamble
- No unsolicited post-action summaries
- Code blocks for anything runnable
- No em dashes
