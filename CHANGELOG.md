# Changelog

## 1.0.0
- Initial release of `agy-plan-review`.
- `SKILL.md`: when to use, the conceptual-prose rule, model selection, reading the verdict, failure modes.
- `scripts/agy-review.sh`: wraps `agy -p` with a direct-question red-team prompt; reads the plan from a file/arg/stdin; optional `-c` context; default model `Gemini 3.5 Flash (High)`.
- Robustness built from real `agy` testing: detects the canned "no active workspace" / model-greeting deflection, retries, and auto-falls-back to `agy`'s default model when a thinking tier is throttled.
