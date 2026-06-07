# agy-review

> Adversarially review *anything* with the `agy` (Antigravity) CLI before you commit to it — a fast, independent second opinion that pokes holes in whatever you give it.

## What It Does

`agy-review` is an AI-agent skill that pipes content into the `agy` CLI's non-interactive print mode and returns a concise red-team critique: questionable assumptions, flaws, risks, gaps, failure modes, and a `SHIP / REVISE / RETHINK` verdict. It's meant to harden a thing *before* you commit to it.

It reviews **whatever you give it** — a plan or design is just one case. Also: a code change, an essay or doc, a product/architecture decision, an argument or pitch, a config, a prompt, a name, an idea. Raw code, numbered specs, and prose all work.

Defaults to **Gemini 3.5 Flash in its highest thinking mode**. The script runs `agy` from a throwaway empty directory, so it never reads or touches your repo — it just asks a question and prints the answer.

## Skill Architecture

```
agy-review/
├── SKILL.md                 # routing + how-to (what it reviews, arguments, reading the verdict)
└── scripts/
    └── agy-review.sh        # wraps `agy --print`: builds the critique prompt, runs it, prints the result
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
Env: `AGY_REVIEW_MODEL`, `AGY_PRINT_TIMEOUT` (2m), `AGY_HARD_TIMEOUT` (150s).
Exit codes: `0` critique printed · `1` usage error · `2` `agy` not found or returned nothing.

## Implementation note

`agy`'s `-p` / `--print` / `--prompt` flag takes the prompt as its **value**, so every other flag (`--model`, `--print-timeout`) must come *before* it, with `-p "$PROMPT"` last. Put `-p` first and it silently swallows the next flag as the prompt. The script handles this; keep the ordering if you edit it.

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
