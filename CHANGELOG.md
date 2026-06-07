# Changelog

## 1.0.0
- Initial release of `agy-review` — adversarial review of *anything* (plan, design, code change, writing, decision, argument, config, idea) via the `agy` (Antigravity) CLI.
- `SKILL.md`: what it reviews, the prose-vs-raw-code rule, model selection, reading the verdict, the leash, failure modes.
- `scripts/agy-review.sh`: wraps `agy -p` with a direct critique prompt; reads content from a file/arg/stdin; optional `-c` context; default model `Gemini 3.5 Flash (High)`.
- Robustness built from real `agy` testing: detects the canned "no active workspace" / model-greeting deflection AND agentic-wander output, runs `agy` from a throwaway empty dir, hard-kills on timeout, and never crawls your repo (exits 3 instead of returning junk).
