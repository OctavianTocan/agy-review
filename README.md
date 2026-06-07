# agy-plan-review

> Adversarially review a plan with the `agy` (Antigravity) CLI before you build it — a fast, independent second opinion that pokes holes in your approach.

## What It Does

`agy-plan-review` is an AI-agent skill that pipes a plan into the `agy` CLI's non-interactive print mode (`agy -p`) with a tight, direct-question prompt, and returns a concise critique: hidden assumptions, failure modes, missing steps, and a `SHIP / REVISE / RETHINK` verdict. It's meant to harden a plan *before* implementation.

It defaults to **Gemini 3.5 Flash in its highest thinking mode** and is built — from a lot of hammering on the real CLI — to be defensive about three `agy` behaviours:

1. **Code-spec deflection.** `agy` is a coding-agent harness. Prompts that read like "implement this" — numbered steps with named APIs/functions (`setInterval`, `Express`, `HTTP 429`) — make it ask for a workspace instead of reviewing. **Feed a conceptual prose summary** and it reviews well.
2. **Throttled-tier deflection.** A heavily-used thinking tier can start returning a canned greeting. The script detects it and retries.
3. **Agentic wander.** Unleashed, `agy` can crawl/grep whatever workspace it remembers. The script runs it from a **fresh empty directory**, hard-kills it on timeout, and **refuses to print wander logs** as a review — so it can never go spelunking in your codebase.

## Skill Architecture

```
agy-plan-review/
├── SKILL.md                 # routing + how-to (when to use, the conceptual-prose rule, the leash, reading results)
└── scripts/
    └── agy-review.sh        # wraps `agy -p`: builds the prompt, leashes agy, detects deflection/wander, retries
```

## Usage

```bash
# pipe a conceptual plan in
printf '%s\n' "$PLAN_PROSE" | scripts/agy-review.sh -

# from a file, with context about goal/constraints
scripts/agy-review.sh -f plan.md -c "must ship this sprint; Postgres only"

# pick a different model
scripts/agy-review.sh -m "Gemini 3.1 Pro (High)" -f plan.md
```

Options: `-f/--file`, `-c/--context`, `-m/--model`, `-h/--help`.
Env: `AGY_REVIEW_MODEL`, `AGY_PRINT_TIMEOUT` (80s), `AGY_HARD_TIMEOUT` (95s), `AGY_REVIEW_RETRIES` (3).
Exit codes: `0` critique printed · `1` usage error · `2` `agy` not found · `3` no clean review after retries (rephrase more conceptually, or try a different tier).

## The golden rule

Describe the plan's **design and decisions in plain prose**, not as a literal code spec:

- ❌ `1. per-IP counter in Express middleware; 2. HTTP 429 over 100 req/min; 3. reset via setInterval(fn,60000)`
- ✅ `keep a per-user request count in each server's memory, clear it on a 60-second timer, reject over-limit requests until the next window; several servers behind a load balancer`

## Requirements

- The `agy` (Antigravity) CLI on your `PATH` (`agy --version`, `agy models`).

## Installation

Install with Vercel's Skills CLI (recommended):

```bash
npx skills add OctavianTocan/agy-plan-review
```

Or copy the directory into your agent's skills folder:

```bash
cp -r agy-plan-review ~/.claude/skills/       # Claude Code (personal)
cp -r agy-plan-review ~/.agents/skills/       # all local agents
```

## License

MIT
