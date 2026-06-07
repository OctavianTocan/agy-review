---
name: agy-review
description: Adversarially review anything - a plan, design, code change, piece of writing, decision, argument, config, or idea - with the `agy` (Antigravity) CLI. A fast second opinion from an independent model that pokes holes in whatever you give it: questionable assumptions, flaws, risks, gaps, failure modes, and a SHIP/REVISE/RETHINK verdict. Use when you want to red-team / stress-test / sanity-check / critique something, "poke holes in this", "what am I missing", "what's wrong with this", "get a second opinion", "review this with agy", or harden it before committing. Pairs with brainstorming and writing-plans.
stages: [plan]
---

# agy-review

Run anything past the `agy` CLI for a quick adversarial critique — questionable assumptions, flaws, risks, gaps, failure modes, and a SHIP/REVISE/RETHINK verdict — from a second, independent model. Use it to harden a thing *before* you commit to it, not to replace your own judgment.

It reviews **whatever you give it** — a plan or design is just one case. Also: a code change, an essay or doc, a product/architecture decision, an argument or pitch, a config, a prompt, a name, an idea.

## When to use

- You've drafted *something* (a plan after `brainstorming`/`writing-plans`, a design, a piece of writing, a decision) and want it stress-tested before committing.
- You want a fast "what am I missing / what's wrong with this?" second opinion.
- Someone asks you to red-team, poke holes in, critique, or sanity-check anything.

Don't bother for trivial throwaways.

## How to run it

One script does everything: `scripts/agy-review.sh`. Give it the content via stdin, a file, or an argument.

```bash
# pipe content in (most common when reviewing your own draft)
printf '%s\n' "$THING" | scripts/agy-review.sh -

# from a file, with optional context about what it is / the goal
scripts/agy-review.sh -f design.md -c "B2B SaaS onboarding flow; must ship this sprint"
scripts/agy-review.sh -f essay.md  -c "blog post for a technical audience"
```

It prints the critique to stdout and exits `0`. Read the bullets, then weigh them — adopt the real ones, dismiss the off-base ones, and tell the user which is which. Use `-c/--context` to say what the thing *is* so the critique is on-target.

## The one rule that matters: prose reviews cleanly; raw code deflects

`agy` is a coding-agent harness. If your input reads like *"implement this"* — raw code or a spec full of named APIs/functions/endpoints (`setInterval`, `Express`, `HTTP 429`, `useEffect`, a literal SQL statement) — it classifies the input as a workspace coding task and returns a canned *"no active workspace…"* greeting instead of reviewing.

Prose reviews directly (plans, designs, writing, decisions, arguments). To review **code**, describe what it does and the key decisions in plain prose rather than pasting the raw spec:

- ❌ `1. per-IP counter in Express middleware; 2. HTTP 429 over 100 req/min; 3. reset via setInterval(fn,60000)`
- ✅ `Rate-limit the API by keeping a per-user request count in each server's memory and clearing it on a fixed 60-second timer; reject over-limit requests until the next window. Several servers behind a load balancer.`

If the script exits `3`, the input still looked like a raw code spec (or the model tier was throttled): make it more conceptual and rerun.

## It keeps `agy` on a leash (don't worry about your repo)

`agy` is agentic and, left alone, can wander off crawling whatever workspace it remembers. The script prevents that: it runs `agy` from a throwaway empty directory, never points it at your repo, hard-kills it on timeout, and refuses to print "agent wander" logs as if they were a review. The skill is **read-only toward your codebase** — it asks `agy` a question and prints the answer, nothing more. Worst case is exit `3` (no review), never an edit or a crawl.

## Model

Defaults to **`Gemini 3.5 Flash (High)`** (Flash in its highest thinking mode), per preference. Override with `AGY_REVIEW_MODEL="<name>"` (see `agy models` for exact strings) or `-m`. A heavily-used tier can get throttled and start deflecting; rather than let `agy` loose on your repo, the script just retries and then reports (exit `3`) — retry later or pick a less-used tier.

## Reading the result

The last line is `VERDICT: SHIP / REVISE / RETHINK - <biggest issue>`. Treat it as input, not a verdict you must obey:

- **SHIP** — no blocking issues found; still skim the bullets.
- **REVISE** — fix the flagged issues, then proceed.
- **RETHINK** — it may be fundamentally off; reconsider before committing.

Always reconcile the critique with your own reasoning and the actual context. A second model is good at catching blind spots and bad at knowing your context — keep what's true, drop what isn't, and tell the user which is which.

## Notes & failure modes

- Needs the `agy` CLI on `PATH` (`agy --version`). Missing → exit `2`.
- Reviews typically run in ~5–40s.
- Env knobs: `AGY_REVIEW_MODEL` · `AGY_PRINT_TIMEOUT` (80s) · `AGY_HARD_TIMEOUT` (95s) · `AGY_REVIEW_RETRIES` (3).
- Exit codes: `0` critique printed · `1` usage error · `2` `agy` not found · `3` no clean review after retries (rephrase more conceptually, or try a different tier).
