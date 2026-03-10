#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/continuous-run/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: continuous-codex.sh [options]

Runs Codex in a persistent implementation loop against a target repository.
Launch it from inside the target repo or pass `--repo PATH`.

Options:
  --repo PATH            Target git repository. Default: current working tree.
  --once                 Run exactly one Codex round and exit.
  --reset-session        Discard any saved Codex session id and start fresh.
  --prompt-file PATH     Use a different prompt template.
  --interval SECONDS     Sleep between successful rounds. Default: 5
  --max-idle ROUNDS      Stop after this many unchanged repo-state rounds. Default: 3
  --max-failures COUNT   Stop after this many failed Codex rounds. Default: 1
  --parallel             Enable prompt guidance for Codex multi-agent parallel work.
  --safe                 Use `codex exec --full-auto` instead of bypass mode.
  --help                 Show this help.

Environment overrides:
  CONTINUOUS_RUN_REPO           Default target repository.
  CONTINUOUS_RUN_ENABLE_PARALLEL
                                Enable parallel prompt guidance (`1`, `true`, `yes`, `on`).
  CODEX_STATE_DIR               State directory. Default: <repo>/.codex-loop
  CODEX_PROMPT_FILE             Prompt template path.
  CODEX_INTERVAL                Sleep between rounds.
  CODEX_MAX_IDLE                Max unchanged rounds before stopping.
  CODEX_MAX_FAILURES            Max failed rounds before stopping.
  CODEX_EXEC_MODE               `dangerous` (default) or `safe`
  CODEX_MODEL                   Optional model passed to Codex.
  CODEX_EXTRA_FLAGS             Extra flags appended to Codex commands as a shell-style string.

Stop mechanism:
  Touch <repo>/.codex-loop/STOP while the loop is running.
EOF
}

PROMPT_FILE="${CODEX_PROMPT_FILE:-$SCRIPT_DIR/prompts/continuous-implementation.md}"
INTERVAL="${CODEX_INTERVAL:-5}"
MAX_IDLE="${CODEX_MAX_IDLE:-3}"
MAX_FAILURES="${CODEX_MAX_FAILURES:-1}"
EXEC_MODE="${CODEX_EXEC_MODE:-dangerous}"
REPO_ARG="${CONTINUOUS_RUN_REPO:-}"
RUN_ONCE=0
RESET_SESSION=0
PARALLEL_ENABLED=0

if continuous_run_flag_enabled "${CONTINUOUS_RUN_ENABLE_PARALLEL:-0}"; then
  PARALLEL_ENABLED=1
else
  status=$?
  if [[ "$status" -eq 2 ]]; then
    exit 1
  fi
fi

require_option_value() {
  local option="$1"
  local value

  if ! value="$(continuous_run_require_option_value "$option" "${2-}")"; then
    printf '\n' >&2
    usage >&2
    exit 1
  fi

  printf '%s\n' "$value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_ARG="$(require_option_value "$1" "${2-}")"
      shift 2
      ;;
    --once)
      RUN_ONCE=1
      shift
      ;;
    --reset-session)
      RESET_SESSION=1
      shift
      ;;
    --prompt-file)
      PROMPT_FILE="$(require_option_value "$1" "${2-}")"
      shift 2
      ;;
    --interval)
      INTERVAL="$(require_option_value "$1" "${2-}")"
      shift 2
      ;;
    --max-idle)
      MAX_IDLE="$(require_option_value "$1" "${2-}")"
      shift 2
      ;;
    --max-failures)
      MAX_FAILURES="$(require_option_value "$1" "${2-}")"
      shift 2
      ;;
    --parallel)
      PARALLEL_ENABLED=1
      shift
      ;;
    --safe)
      EXEC_MODE="safe"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v codex >/dev/null 2>&1; then
  printf 'codex CLI not found in PATH\n' >&2
  exit 1
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  printf 'Prompt file not found: %s\n' "$PROMPT_FILE" >&2
  exit 1
fi

REPO_ROOT="$(continuous_run_resolve_repo_root "$REPO_ARG")"
STATE_DIR="${CODEX_STATE_DIR:-$REPO_ROOT/.codex-loop}"

case "$EXEC_MODE" in
  dangerous)
    AUTO_FLAGS=(--dangerously-bypass-approvals-and-sandbox)
    ;;
  safe)
    AUTO_FLAGS=(--full-auto)
    ;;
  *)
    printf 'Unsupported CODEX_EXEC_MODE: %s\n' "$EXEC_MODE" >&2
    exit 1
    ;;
esac

EXTRA_FLAGS=()
if [[ -n "${CODEX_MODEL:-}" ]]; then
  EXTRA_FLAGS+=(-m "$CODEX_MODEL")
fi
if [[ -n "${CODEX_EXTRA_FLAGS:-}" ]]; then
  # Intentional word splitting for user-provided extra CLI flags.
  # shellcheck disable=SC2206
  USER_EXTRA_FLAGS=(${CODEX_EXTRA_FLAGS})
  EXTRA_FLAGS+=("${USER_EXTRA_FLAGS[@]}")
fi

mkdir -p "$STATE_DIR/logs"
SESSION_FILE="$STATE_DIR/session_id"
LATEST_JSON="$STATE_DIR/latest.jsonl"
LATEST_MESSAGE="$STATE_DIR/latest-message.txt"
NEXT_ACTION="$STATE_DIR/next-action.md"
PARALLEL_PROMPT="$(continuous_run_parallel_prompt codex "$PARALLEL_ENABLED")"

if [[ "$RESET_SESSION" -eq 1 ]]; then
  rm -f "$SESSION_FILE"
fi

round=0
idle_rounds=0
failure_count=0

compose_prompt() {
  local round_no="$1"
  continuous_run_compose_prompt \
    "$PROMPT_FILE" \
    "$round_no" \
    "$REPO_ROOT" \
    "$NEXT_ACTION" \
    "$PARALLEL_PROMPT"
}

extract_thread_id() {
  sed -n 's/.*"thread_id":"\([^"]*\)".*/\1/p' "$1" | head -n 1
}

run_codex_round() {
  local round_no="$1"
  local prompt_text json_log last_message_log session_id
  prompt_text="$(compose_prompt "$round_no")"
  json_log="$STATE_DIR/logs/round-$(printf '%04d' "$round_no").jsonl"
  last_message_log="$STATE_DIR/logs/round-$(printf '%04d' "$round_no").last.txt"

  if [[ -f "$SESSION_FILE" ]]; then
    session_id="$(cat "$SESSION_FILE")"
    if ! printf '%s\n' "$prompt_text" | \
      codex exec resume \
        "${AUTO_FLAGS[@]}" \
        "${EXTRA_FLAGS[@]}" \
        --json \
        -o "$last_message_log" \
        "$session_id" \
        - > "$json_log"; then
      [[ -f "$json_log" ]] && cp "$json_log" "$LATEST_JSON"
      [[ -f "$last_message_log" ]] && cp "$last_message_log" "$LATEST_MESSAGE"
      return 1
    fi
  else
    if ! printf '%s\n' "$prompt_text" | \
      codex exec \
        "${AUTO_FLAGS[@]}" \
        "${EXTRA_FLAGS[@]}" \
        --json \
        --color never \
        -o "$last_message_log" \
        - > "$json_log"; then
      [[ -f "$json_log" ]] && cp "$json_log" "$LATEST_JSON"
      [[ -f "$last_message_log" ]] && cp "$last_message_log" "$LATEST_MESSAGE"
      return 1
    fi

    session_id="$(extract_thread_id "$json_log")"
    if [[ -z "$session_id" ]]; then
      printf 'Failed to extract Codex session id from %s\n' "$json_log" >&2
      return 1
    fi
    printf '%s\n' "$session_id" > "$SESSION_FILE"
  fi

  cp "$json_log" "$LATEST_JSON"
  cp "$last_message_log" "$LATEST_MESSAGE"
}

printf 'Repo: %s\n' "$REPO_ROOT"
printf 'State dir: %s\n' "$STATE_DIR"
printf 'Prompt file: %s\n' "$PROMPT_FILE"
printf 'Mode: %s\n' "$EXEC_MODE"
printf 'Parallel guidance: %s\n' "$([[ "$PARALLEL_ENABLED" -eq 1 ]] && printf 'enabled' || printf 'disabled')"

before_fp="$(continuous_run_repo_fingerprint "$REPO_ROOT")"

while true; do
  if [[ -f "$STATE_DIR/STOP" ]]; then
    printf 'Stop file detected at %s/STOP\n' "$STATE_DIR"
    break
  fi

  round=$((round + 1))
  printf '\n== Codex round %d ==\n' "$round"

  if run_codex_round "$round"; then
    failure_count=0
    printf 'Session: %s\n' "$(cat "$SESSION_FILE")"
    printf 'Last message:\n'
    cat "$LATEST_MESSAGE"
    printf '\n'

    after_fp="$(continuous_run_repo_fingerprint "$REPO_ROOT")"
    if [[ "$after_fp" == "$before_fp" ]]; then
      idle_rounds=$((idle_rounds + 1))
      printf 'Repo state unchanged after round %d (%d/%d idle rounds)\n' \
        "$round" "$idle_rounds" "$MAX_IDLE"
    else
      idle_rounds=0
      before_fp="$after_fp"
      printf 'Repo state changed after round %d\n' "$round"
    fi

    if [[ "$RUN_ONCE" -eq 1 ]]; then
      break
    fi

    if (( idle_rounds >= MAX_IDLE )); then
      printf 'Reached max idle rounds (%d). Stopping.\n' "$MAX_IDLE"
      break
    fi

    sleep "$INTERVAL"
  else
    failure_count=$((failure_count + 1))
    printf 'Codex round %d failed (%d/%d)\n' "$round" "$failure_count" "$MAX_FAILURES" >&2
    if [[ -f "$LATEST_MESSAGE" ]]; then
      printf 'Last message before failure:\n' >&2
      cat "$LATEST_MESSAGE" >&2
      printf '\n' >&2
    fi
    if (( failure_count >= MAX_FAILURES )); then
      printf 'Reached max failures. Stopping.\n' >&2
      exit 1
    fi
    sleep "$INTERVAL"
  fi
done
