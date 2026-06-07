# agy-review

> Adversarially review *anything* with the `agy` (Antigravity) CLI before you commit to it — a fast, independent, leashed second opinion that pokes holes in whatever you give it.

## What It Does

`agy-review` is an AI-agent skill that pipes content into the `agy` CLI's non-interactive print mode (`agy -p`) with a tight, direct critique prompt, and returns a concise review: questionable assumptions, flaws, risks, gaps, failure modes, and a `SHIP / REVISE / RETHINK` verdict. It's meant to harden a thing *before* you commit to it.

It reviews **whatever you give it** — a plan or design is just one case. Also: a code change, an essay or doc, a product/architecture decision, an argument or pitch, a config, a prompt, a name, an idea.

It defaults to **Gemini 3.5 Flash in its highest thinking mode** and is built — from a lot of hammering on the real CLI — to be defensive about three `agy` behaviours:

1. **Code-spec deflection.** `agy` is a coding-agent harness. Input that reads like "implement this" — raw code / named APIs/functions (`setInterval`, `Express`, `HTTP 429`) — makes it ask for a workspace instead of reviewing. **Prose reviews cleanly; describe code conceptually.**
2. **Throttled-tier deflection.** A heavily-used thinking tier can start returning a canned greeting. The script detects it and retries.
3. **Agentic wander.** Unleashed, `agy` can crawl/grep whatever workspace it remembers. The script runs it from a **fresh empty directory**, hard-kills it on timeout, and **refuses to print wander logs** as a review — so it can never go spelunking in your codebase.

## Skill Architecture

```
agy-review/
├── SKILL.md                 # routing + how-to (what it reviews, the prose-vs-code rule, the leash, reading results)
└── scripts/
    └── agy-review.sh        # wraps `agy -p`: builds the critique prompt, leashes agy, detects deflection/wander, retries
```

## Usage

```bash
# pipe content in
printf '%s\n' "$THING" | scripts/agy-review.sh -

# from a file, with context about what it is / goals
scripts/agy-review.sh -f design.md -c "must ship this sprint; Postgres only"
scripts/agy-review.sh -f essay.md  -c "blog post for a technical audience"

# pick a different model
scripts/agy-review.sh -m "Gemini 3.1 Pro (High)" -f decision.md
```

Options: `-f/--file`, `-c/--context`, `-m/--model`, `-h/--help`.
Env: `AGY_REVIEW_MODEL`, `AGY_PRINT_TIMEOUT` (80s), `AGY_HARD_TIMEOUT` (95s), `AGY_REVIEW_RETRIES` (3).
Exit codes: `0` critique printed · `1` usage error · `2` `agy` not found · `3` no clean review after retries (rephrase more conceptually, or try a different tier).

## The golden rule

Prose reviews cleanly. To review **code**, describe its design and decisions in plain prose, not as a raw spec:

- ❌ `1. per-IP counter in Express middleware; 2. HTTP 429 over 100 req/min; 3. reset via setInterval(fn,60000)`
- ✅ `keep a per-user request count in each server's memory, clear it on a 60-second timer, reject over-limit requests until the next window; several servers behind a load balancer`

## Requirements

- The `agy` (Antigravity) CLI on your `PATH` (`agy --version`, `agy models`).

## Installation

Install with Vercel's Skills CLI (recommended):

```bash
npx skills add OctavianTocan/agy-review
```

Or copy the directory into your agent's skills folder:

```bash
cp -r agy-review ~/.claude/skills/       # Claude Code (personal)
cp -r agy-review ~/.agents/skills/       # all local agents
```

## License

MIT
