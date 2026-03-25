#!/bin/zsh
# pm-cmux.sh — cmux workspace management for PM orchestrator
# Source this file or call functions directly:
#   source scripts/pm-cmux.sh
#   pm_launch_agent backender "Phase 1.4 — Backend Scaffold" "Create FastAPI app skeleton..."
#   pm_update_agent backender working
#   pm_set_progress 0.35 "Phase 1: 15/42 tasks"
#   pm_agent_done backender
#   pm_agent_failed backender "Missing dependency"

set -euo pipefail

# ── Agent color/emoji map ──────────────────────────────────────────
typeset -A AGENT_COLORS=(
  pm        "#007AFF"
  backender "#34c759"
  frontender "#5AC8FA"
  db-architect "#FFD60A"
  ai-engineer "#FF2D92"
  channel-engineer "#FF9500"
  test-writer "#FFFFFF"
  security-auditor "#FF3B30"
)

typeset -A AGENT_EMOJI=(
  pm        "🔵"
  backender "🟢"
  frontender "🔷"
  db-architect "🟡"
  ai-engineer "🟣"
  channel-engineer "🟠"
  test-writer "⚪"
  security-auditor "🔴"
)

typeset -A STATUS_EMOJI=(
  starting  "⏳"
  working   "⚡"
  waiting   "💤"
  reviewing "🔍"
  done      "✅"
  failed    "❌"
  blocked   "🚫"
)

# ── Helpers ─────────────────────────────────────────────────────────
_cmux_available() {
  command -v cmux &>/dev/null
}

_get_color() {
  local agent="$1"
  echo "${AGENT_COLORS[$agent]:-#8E8E93}"
}

_get_emoji() {
  local agent="$1"
  echo "${AGENT_EMOJI[$agent]:-🔘}"
}

_status_emoji() {
  local st="$1"
  echo "${STATUS_EMOJI[$st]:-▶️}"
}

# ── PM workspace setup ─────────────────────────────────────────────
# Call once when PM session starts
pm_init() {
  _cmux_available || return 0
  cmux rename-workspace "🔵 PM: orchestrator" 2>/dev/null
  cmux set-status pm "active" --color "#007AFF" 2>/dev/null
  cmux log --level info --source pm -- "PM orchestrator initialized" 2>/dev/null
}

# ── Launch agent in new cmux workspace ─────────────────────────────
# Usage: pm_launch_agent <agent> <task-title> <prompt>
# Example: pm_launch_agent backender "Phase 1.4" "Create the FastAPI scaffold..."
pm_launch_agent() {
  local agent="$1"
  local task_title="$2"
  local prompt="$3"
  local color=$(_get_color "$agent")
  local emoji=$(_get_emoji "$agent")

  _cmux_available || { echo "cmux not available"; return 1; }

  # Create new workspace
  local ws_output
  ws_output=$(cmux new-workspace --cwd "$(pwd)" 2>/dev/null)
  local ws_ref
  ws_ref=$(echo "$ws_output" | grep -o 'workspace:[0-9]*' | head -1)

  if [[ -z "$ws_ref" ]]; then
    echo "Failed to create workspace"
    return 1
  fi

  # Name and style the workspace
  cmux rename-workspace "${emoji} ${agent}: ${task_title}" --workspace "$ws_ref" 2>/dev/null
  cmux set-status agent "${agent}" --color "$color" --workspace "$ws_ref" 2>/dev/null
  cmux set-status task "starting" --color "#ff9f0a" --workspace "$ws_ref" 2>/dev/null

  # Log in PM workspace
  cmux log --level info --source pm -- "Launched ${agent} → ${task_title}" 2>/dev/null

  # Log in agent workspace
  cmux log --level info --source pm -- "Task: ${task_title}" --workspace "$ws_ref" 2>/dev/null

  # Set PM_SIGNAL_NAME so Stop hook signals with workspace ref
  # Then launch claude with the agent
  local prompt_file="/tmp/pm-prompt-${agent}-$$.txt"
  echo "$prompt" > "$prompt_file"
  cmux send --workspace "$ws_ref" "export PM_SIGNAL_NAME=${ws_ref} && claude --agent ${agent} --dangerously-skip-permissions < ${prompt_file}" 2>/dev/null
  cmux send-key --workspace "$ws_ref" Enter 2>/dev/null

  # Update PM sidebar with active agent
  cmux set-status "$agent" "$(_status_emoji starting) starting" --color "$color" 2>/dev/null

  echo "$ws_ref"
}

# ── Update agent status ────────────────────────────────────────────
# Usage: pm_update_agent <agent> <status> [workspace-id]
# Statuses: starting, working, waiting, reviewing, done, failed, blocked
pm_update_agent() {
  local agent="$1"
  local st="$2"
  local ws_id="${3:-}"
  local color=$(_get_color "$agent")
  local s_emoji=$(_status_emoji "$st")

  _cmux_available || return 0

  # Update PM sidebar
  cmux set-status "$agent" "${s_emoji} ${st}" --color "$color" 2>/dev/null

  # Update agent workspace if provided
  if [[ -n "$ws_id" ]]; then
    cmux set-status task "$st" --color "$color" --workspace "$ws_id" 2>/dev/null
  fi

  cmux log --level info --source pm -- "${agent}: ${s_emoji} ${st}" 2>/dev/null
}

# ── Agent completed successfully ───────────────────────────────────
pm_agent_done() {
  local agent="$1"
  local ws_id="${2:-}"
  local color=$(_get_color "$agent")

  _cmux_available || return 0

  cmux set-status "$agent" "✅ done" --color "$color" 2>/dev/null
  cmux log --level success --source pm -- "${agent}: ✅ completed" 2>/dev/null
  cmux notify --title "Agent Done" --body "${agent} completed its task" 2>/dev/null

  if [[ -n "$ws_id" ]]; then
    cmux set-status task "done" --color "#34c759" --workspace "$ws_id" 2>/dev/null
    cmux rename-workspace "✅ ${agent}: done" --workspace "$ws_id" 2>/dev/null
  fi
}

# ── Agent failed ───────────────────────────────────────────────────
pm_agent_failed() {
  local agent="$1"
  local reason="${2:-unknown error}"
  local ws_id="${3:-}"

  _cmux_available || return 0

  cmux set-status "$agent" "❌ failed" --color "#FF3B30" 2>/dev/null
  cmux log --level error --source pm -- "${agent}: ❌ ${reason}" 2>/dev/null
  cmux notify --title "Agent Failed" --body "${agent}: ${reason}" 2>/dev/null

  if [[ -n "$ws_id" ]]; then
    cmux set-status task "failed" --color "#FF3B30" --workspace "$ws_id" 2>/dev/null
    cmux rename-workspace "❌ ${agent}: failed" --workspace "$ws_id" 2>/dev/null
  fi
}

# ── Set overall progress ──────────────────────────────────────────
# Usage: pm_set_progress <0.0-1.0> <label>
pm_set_progress() {
  local progress="$1"
  local label="${2:-}"

  _cmux_available || return 0
  cmux set-progress "$progress" --label "$label" 2>/dev/null
}

# ── Show all active agents ─────────────────────────────────────────
pm_list_agents() {
  _cmux_available || return 0
  cmux list-status 2>/dev/null
}

# ── Read agent workspace output ────────────────────────────────────
pm_read_agent() {
  local ws_id="$1"
  local lines="${2:-50}"

  _cmux_available || return 0
  cmux read-screen --workspace "$ws_id" --lines "$lines" 2>/dev/null
}

# ── Clean up agent workspace ──────────────────────────────────────
pm_cleanup_agent() {
  local agent="$1"
  local ws_id="${2:-}"

  _cmux_available || return 0

  cmux clear-status "$agent" 2>/dev/null

  if [[ -n "$ws_id" ]]; then
    cmux close-workspace --workspace "$ws_id" 2>/dev/null
  fi
}

# ── Phase progress helper ─────────────────────────────────────────
# Usage: pm_phase_progress <phase> <done> <total>
pm_phase_progress() {
  local phase="$1"
  local done="$2"
  local total="$3"
  local pct
  pct=$(echo "scale=2; $done / $total" | bc)

  _cmux_available || return 0
  cmux set-progress "$pct" --label "Phase ${phase}: ${done}/${total}" 2>/dev/null
  cmux log --level progress --source pm -- "Phase ${phase}: ${done}/${total} tasks" 2>/dev/null
}

# ── Dashboard: show all workspaces ────────────────────────────────
pm_dashboard() {
  _cmux_available || { echo "cmux not available"; return 1; }

  echo "=== AIVI Agency — Agent Dashboard ==="
  echo ""
  cmux list-workspaces 2>/dev/null
  echo ""
  echo "--- PM Status ---"
  cmux list-status 2>/dev/null
  echo ""
  echo "--- PM Logs ---"
  cmux list-log --limit 20 2>/dev/null
}

# If sourced, export functions. If run directly, execute command.
if [[ "${ZSH_EVAL_CONTEXT:-}" == "toplevel" ]]; then
  cmd="${1:-help}"
  (( $# > 0 )) && shift
  case "$cmd" in
    init) pm_init ;;
    launch) pm_launch_agent "$@" ;;
    update) pm_update_agent "$@" ;;
    done) pm_agent_done "$@" ;;
    failed) pm_agent_failed "$@" ;;
    progress) pm_set_progress "$@" ;;
    phase) pm_phase_progress "$@" ;;
    list) pm_list_agents ;;
    read) pm_read_agent "$@" ;;
    cleanup) pm_cleanup_agent "$@" ;;
    dashboard) pm_dashboard ;;
    help|*)
      echo "pm-cmux.sh — PM orchestrator cmux integration"
      echo ""
      echo "Usage: pm-cmux.sh <command> [args]"
      echo ""
      echo "Commands:"
      echo "  init                              Initialize PM workspace"
      echo "  launch <agent> <title> <prompt>   Launch agent in new workspace"
      echo "  update <agent> <status> [ws-id]   Update agent status"
      echo "  done <agent> [ws-id]              Mark agent as done"
      echo "  failed <agent> <reason> [ws-id]   Mark agent as failed"
      echo "  progress <0.0-1.0> <label>        Set overall progress bar"
      echo "  phase <num> <done> <total>        Update phase progress"
      echo "  list                              Show all status entries"
      echo "  read <ws-id> [lines]              Read agent workspace output"
      echo "  cleanup <agent> [ws-id]           Clear status & close workspace"
      echo "  dashboard                         Show full dashboard"
      ;;
  esac
fi
