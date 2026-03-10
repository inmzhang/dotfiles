#!/usr/bin/env bash

continuous_run_resolve_repo_root() {
  local requested_repo="${1:-}"
  local repo_root

  if [[ -n "$requested_repo" ]]; then
    if ! repo_root="$(git -C "$requested_repo" rev-parse --show-toplevel 2>/dev/null)"; then
      printf 'Repository path is not inside a git worktree: %s\n' "$requested_repo" >&2
      return 1
    fi
    printf '%s\n' "$repo_root"
    return 0
  fi

  if ! repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf 'Run this from inside the target repository or pass --repo PATH\n' >&2
    return 1
  fi

  printf '%s\n' "$repo_root"
}

continuous_run_flag_enabled() {
  case "${1:-0}" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    0|false|FALSE|no|NO|off|OFF|"")
      return 1
      ;;
    *)
      printf 'Unsupported boolean value: %s\n' "$1" >&2
      return 2
      ;;
  esac
}

continuous_run_repo_fingerprint() {
  local repo_root="$1"
  local head_ref="<no-head>"

  if head_ref="$(git -C "$repo_root" rev-parse --verify HEAD 2>/dev/null)"; then
    :
  fi

  {
    printf '%s\n' "$head_ref"
    git -C "$repo_root" status --short
  } | shasum | awk '{print $1}'
}

continuous_run_require_option_value() {
  local option="$1"
  local value="${2-}"

  if [[ -z "$value" || "$value" == --* ]]; then
    printf 'Option %s requires a value\n' "$option" >&2
    return 1
  fi

  printf '%s\n' "$value"
}

continuous_run_parallel_prompt() {
  local tool="$1"
  local enabled="$2"

  if [[ "$enabled" -eq 1 ]]; then
    case "$tool" in
      codex)
        cat <<'EOF'
Tool-specific guidance:
- Parallel mode is enabled for this run.
- Use multi agents only for independent, materially parallelizable work that can advance in parallel without overlapping write scopes.
- Keep delegated tasks concrete and bounded, and do not wait on sidecar work unless you are blocked on its result.
EOF
        ;;
      claude)
        cat <<'EOF'
Tool-specific guidance:
- Parallel mode is enabled for this run.
- Use parallel agent teams for independent workstreams that can proceed without overlapping edits.
- Keep spawned tasks concrete and bounded, and avoid using extra agents for urgent blocking work.
EOF
        ;;
      *)
        printf 'Unsupported tool for parallel prompt: %s\n' "$tool" >&2
        return 1
        ;;
    esac
    return 0
  fi

  cat <<'EOF'
Tool-specific guidance:
- Parallel mode is disabled for this run. Stay single-threaded unless the user or repo instructions explicitly require otherwise.
EOF
}

continuous_run_compose_prompt() {
  local prompt_file="$1"
  local round_no="$2"
  local repo_root="$3"
  local next_action="$4"
  local tool_prompt="$5"
  local now_utc

  now_utc="$(env TZ=UTC date '+%Y-%m-%d %H:%M:%S UTC')"

  cat <<EOF
$(cat "$prompt_file")

${tool_prompt}

Loop context:
- Round: ${round_no}
- Time: ${now_utc}
- Repository: ${repo_root}
- Saved next-action note path: ${next_action}

Continue from the current repo state. If the previous run ended mid-slice, finish it before starting a new one.
EOF
}
