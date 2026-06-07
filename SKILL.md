---
name: agy-plan-review
description: Adversarially review a plan or design with the `agy` (Antigravity) CLI before committing to it - a fast second opinion from an independent model that pokes holes in your approach. Use when you want to red-team / stress-test / sanity-check a plan, "poke holes in this plan", "what am I missing", "critique my approach", get a second opinion on a design, or harden a plan before implementing. Pairs with brainstorming and writing-plans.
stages: [plan]
---

# agy-plan-review

Run your plan past the `agy` CLI for a quick adversarial critique — hidden assumptions, failure modes, missing steps, and a SHIP/REVISE/RETHINK verdict — from a second, independent model. Use it to harden a plan *before* you implement it, not to replace your own judgment.

## When to use

- You've drafted a plan or design (e.g. after `brainstorming` / `writing-plans`, or in plan mode) and want it stress-tested before committing.
- You want a fast "what am I missing here?" second opinion.
- Someone asks you to red-team, poke holes in, or sanity-check an approach.

Don't bother for trivial one-step changes.

## How to run it

One script does everything: `scripts/agy-review.sh`. Give it the plan via stdin, a file, or an argument.

```bash
# pipe a plan in (most common when reviewing your own draft)
printf '%s\n' "$PLAN_PROSE" | scripts/agy-review.sh -

# or from a file, with optional context about the goal/constraints
scripts/agy-review.sh -f plan.md -c "B2B SaaS, must ship this sprint, Postgres only"
```

It prints the critique to stdout and exits `0`. Read the bullets, then weigh them — adopt the real ones, dismiss the off-base ones, and say which is which.

## The one rule that matters: feed CONCEPTUAL prose, not a code spec

`agy` is a coding-agent harness. If your prompt reads like *"implement this"* — numbered build steps full of named APIs/functions/endpoints (`setInterval`, `Express`, `HTTP 429`, `useEffect`, a specific SQL statement) — it classifies the input as a workspace coding task and returns a canned *"no active workspace…"* greeting instead of reviewing.

So **rewrite your plan as a short design summary in plain prose** before passing it: *what* it does and the *key decisions/assumptions*, not the literal code. Example:

- ❌ `1. Add per-IP counter in Express middleware. 2. Return HTTP 429 over 100 req/min. 3. Reset via setInterval(fn, 60000).`
- ✅ `Rate-limit the API by keeping a per-user request count in each server's memory and clearing it on a fixed 60-second timer; reject requests over the limit until the next window. Several servers run behind a load balancer.`

Conceptual phrasing is what makes the review land. If the script exits `3`, your text still looked like a code spec (or the model tier was throttled): make it more conceptual and rerun.

## It keeps `agy` on a leash (don't worry about your repo)

`agy` is agentic and, left alone, can wander off crawling whatever workspace it remembers. The script prevents that: it runs `agy` from a throwaway empty directory, never points it at your repo, hard-kills it on timeout, and refuses to print "agent wander" logs as if they were a review. The skill is **read-only toward your codebase** — it asks `agy` a question and prints the answer, nothing more. Worst case is exit `3` (no review), never an edit or a crawl.

## Model

Defaults to **`Gemini 3.5 Flash (High)`** (Flash in its highest thinking mode), per preference. Override with `AGY_REVIEW_MODEL="<name>"` (see `agy models` for exact strings) or `-m`. A heavily-used tier can get throttled and start deflecting; rather than let `agy` loose on your repo, the script just retries and then reports (exit `3`) — retry later or pick a less-used tier.

## Reading the result

The last line is `VERDICT: SHIP / REVISE / RETHINK - <biggest risk>`. Treat it as input, not a verdict you must obey:

- **SHIP** — no blocking issues found; still skim the bullets.
- **REVISE** — fix the flagged risks, then proceed.
- **RETHINK** — the approach may be wrong; reconsider before building.

Always reconcile the critique with your own reasoning and the actual constraints. A second model is good at catching blind spots and bad at knowing your context — keep what's true, drop what isn't, and tell the user which is which.

## Notes & failure modes

- Needs the `agy` CLI on `PATH` (`agy --version`). Missing → exit `2`.
- Reviews typically run in ~5–40s.
- Env knobs: `AGY_REVIEW_MODEL` · `AGY_PRINT_TIMEOUT` (80s) · `AGY_HARD_TIMEOUT` (95s) · `AGY_REVIEW_RETRIES` (3).
- Exit codes: `0` critique printed · `1` usage error · `2` `agy` not found · `3` no clean review after retries (rephrase more conceptually, or try a different tier).
