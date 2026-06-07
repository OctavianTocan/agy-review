#!/usr/bin/env bash
# agy-review.sh — get an adversarial critique of a PLAN from the `agy` CLI.
#
# Pipes your plan into `agy -p` (Antigravity CLI, non-interactive) as a direct
# review question so a second, independent model pokes holes in it before you
# commit. Default model: Gemini 3.5 Flash in its highest thinking mode.
#
# `agy` is a coding-agent harness, so this script keeps it on a short leash and
# is defensive about three real behaviours (all observed on a live box):
#   1. CODE-SPEC deflection. Prompts that read like "implement this" (named
#      APIs/functions/endpoints: setInterval, Express, "HTTP 429", useEffect)
#      make agy ask for a workspace and return a canned "no active workspace"
#      greeting instead of reviewing. Feed CONCEPTUAL prose and it reviews well.
#   2. Throttled-tier deflection. A heavily-used thinking tier can start
#      returning that same greeting. The script detects it and retries.
#   3. Agentic wander. Left unleashed, agy can start crawling/grepping whatever
#      workspace it remembers. This script runs it from a FRESH EMPTY directory,
#      hard-kills it on timeout, and refuses to print wander logs as a "review".
# It only ever prints a genuine critique; otherwise it exits 3 (rephrase/retry).
#
# Usage:
#   agy-review.sh -f plan.md                 # review a plan file
#   agy-review.sh "<the plan text>"          # review an inline string
#   echo "<plan>" | agy-review.sh -          # read the plan from stdin
#   agy-review.sh -f plan.md -c "context..." # add goal/constraints context
#
# Options:
#   -f, --file FILE     read the plan from FILE
#   -c, --context STR   extra context (goal, constraints) to ground the review
#   -m, --model NAME    model (default $AGY_REVIEW_MODEL or "Gemini 3.5 Flash (High)")
#   -h, --help          show this help
#
# Env: AGY_REVIEW_MODEL · AGY_PRINT_TIMEOUT (80s) · AGY_HARD_TIMEOUT (95s) · AGY_REVIEW_RETRIES (3)
# Exit: 0 critique printed · 1 usage error · 2 agy missing · 3 no clean review (rephrase/retry)
set -euo pipefail

MODEL="${AGY_REVIEW_MODEL:-Gemini 3.5 Flash (High)}"
PRINT_TIMEOUT="${AGY_PRINT_TIMEOUT:-80s}"
HARD_TIMEOUT="${AGY_HARD_TIMEOUT:-95}"
RETRIES="${AGY_REVIEW_RETRIES:-3}"
PLAN=""; CONTEXT=""

usage() { sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-1}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -f|--file)    [ -r "${2:-}" ] || { echo "error: cannot read file '${2:-}'" >&2; exit 1; }; PLAN="$(cat "$2")"; shift 2 ;;
    -c|--context) CONTEXT="${2:-}"; shift 2 ;;
    -m|--model)   MODEL="${2:-}"; shift 2 ;;
    -h|--help)    usage 0 ;;
    -)            PLAN="$(cat -)"; shift ;;
    -*)           echo "error: unknown option '$1'" >&2; usage 1 ;;
    *)            PLAN="$1"; shift ;;
  esac
done
if [ -z "$PLAN" ] && [ ! -t 0 ]; then PLAN="$(cat -)"; fi
[ -n "$PLAN" ] || { echo "error: no plan provided (use -f FILE, an argument, or stdin)" >&2; usage 1; }
command -v agy >/dev/null 2>&1 || { echo "error: 'agy' CLI not found on PATH" >&2; exit 2; }

CTX=""
[ -n "$CONTEXT" ] && CTX="

Context (goal / constraints): ${CONTEXT}"

# Direct-question framing ("you are a reviewer / red team" makes agy go agentic;
# a plain question gets answered). "Approach:" not "Plan:" for the same reason.
PROMPT="What are the main ways the approach below could fail or turn out to be a bad idea? Give the key risks as short bullets - hidden assumptions, failure modes and edge cases, and missing steps - then a final line: VERDICT: SHIP / REVISE / RETHINK - <the single biggest risk>. Be specific and skeptical; do not restate or praise it; just answer.

Approach:
${PLAN}${CTX}"

# A response is NOT a usable review if it is empty/tiny, a deflection greeting,
# or an agentic wander log (a stream of "I will run / I am going to check ...").
is_bad() {
  local s="$1" t
  t="$(printf '%s' "$s" | tr -d '[:space:]')"
  [ -z "$t" ] && return 0
  [ "${#t}" -lt 80 ] && return 0
  printf '%s' "$s" | grep -qiE \
    "i am (currently )?(running|powered|using)|currently (running|powered|using)|running on the .* model|powered by .* gemini|summary of work|how can i help|help you with your coding|active workspace|new project director|start a new project|i (will|am going to) (run|list|view|check|search|read|use)|git grep|grep_search|timed out waiting for response" \
    && return 0
  return 1
}

review_once() {
  local d; d="$(mktemp -d)"
  ( cd "$d" && timeout -k 5s "$HARD_TIMEOUT" agy -p --model "$MODEL" --print-timeout "$PRINT_TIMEOUT" "$PROMPT" 2>&1 ) || true
  rm -rf "$d" 2>/dev/null || true
}

i=0; out=""
while [ "$i" -lt "$RETRIES" ]; do
  i=$((i+1))
  out="$(review_once)"
  if ! is_bad "$out"; then printf '%s\n' "$out"; exit 0; fi
  echo "agy-review: attempt ${i}/${RETRIES} did not return a clean review (deflection/wander); retrying..." >&2
done

{
  echo "agy-review: agy did not return a usable review after ${RETRIES} attempts."
  echo "Likely cause: the plan reads like a code spec (named APIs/functions such as"
  echo "  setInterval / Express / 'HTTP 429') so agy wants a workspace, OR the model tier"
  echo "  '${MODEL}' is throttled. Both surface as a canned greeting."
  echo "Fix: rewrite the plan as a CONCEPTUAL design summary in plain prose (what it does and"
  echo "  the key decisions/assumptions), drop framework/function/endpoint names, and rerun;"
  echo "  or try a different/less-used tier via AGY_REVIEW_MODEL (see 'agy models')."
} >&2
exit 3
