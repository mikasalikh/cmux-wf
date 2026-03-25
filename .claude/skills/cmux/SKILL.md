---
name: cmux
description: Manage cmux workspaces — launch agents, split panes, monitor output, set status, browser, notifications. Use when orchestrating parallel work, managing workspace layout, or interacting with cmux terminal multiplexer.
allowed-tools: Bash, Read
---

# cmux — Workspace & Agent Orchestration

You manage cmux workspaces for the AIVI Agency project. cmux is a terminal workspace manager with sidebar status, progress bars, logging, browser panels, notifications, and multi-pane layouts.

## Quick Reference

### Availability Check

```bash
[ -S "${CMUX_SOCKET_PATH:-/tmp/cmux.sock}" ] && command -v cmux &>/dev/null && echo "cmux OK" || echo "cmux unavailable"
```

Always check before running cmux commands. All commands should have `2>/dev/null` to gracefully handle edge cases.

---

## 1. Workspace Management

### List / Inspect
```bash
cmux list-workspaces                          # all workspaces
cmux current-workspace                        # active workspace
cmux tree                                     # full tree: windows > workspaces > panes > surfaces
cmux tree --workspace workspace:2             # tree for specific workspace
cmux identify                                 # identify current workspace/surface
```

### Create / Switch / Close
```bash
cmux new-workspace --cwd ~/agency             # new workspace in directory
cmux new-workspace --command "htop"           # new workspace running a command
cmux select-workspace --workspace workspace:2 # switch to workspace
cmux close-workspace --workspace workspace:2  # close workspace
cmux rename-workspace "my title"              # rename current workspace
cmux rename-workspace "title" --workspace workspace:2  # rename specific
```

### Reorder
```bash
cmux reorder-workspace --workspace workspace:3 --index 1       # move to position
cmux reorder-workspace --workspace workspace:3 --before workspace:1  # move before another
```

---

## 2. Panes & Splits

### Create Splits
```bash
cmux new-split right                          # split current pane right
cmux new-split down                           # split current pane down
cmux new-split left --workspace workspace:2   # split specific workspace
cmux new-pane --direction right               # new terminal pane to the right
cmux new-pane --type browser --direction right # browser pane to the right
```

### Navigate Panes
```bash
cmux list-panes                               # panes in current workspace
cmux list-panes --workspace workspace:2       # panes in specific workspace
cmux focus-pane --pane pane:1                 # focus a pane
cmux last-pane                                # toggle to last active pane
```

### Resize / Swap / Move
```bash
cmux resize-pane --pane pane:1 -R --amount 20  # grow right by 20
cmux resize-pane --pane pane:1 -D --amount 10  # grow down by 10
cmux swap-pane --pane pane:1 --target-pane pane:2  # swap two panes
cmux break-pane --pane pane:1                 # break pane into new workspace
cmux join-pane --target-pane pane:2           # join current into target
```

### Surfaces (tabs within panes)
```bash
cmux list-pane-surfaces                       # surfaces in current pane
cmux new-surface --type terminal              # new terminal tab in current pane
cmux new-surface --type browser --url "http://localhost:5173"  # browser tab
cmux close-surface --surface surface:3        # close a surface
cmux move-surface --surface surface:3 --pane pane:2  # move surface to another pane
cmux rename-tab "API Logs" --surface surface:1       # rename surface tab
```

---

## 3. Sidebar — Status, Progress, Logs

### Status Pills (key-value pairs in sidebar)
```bash
cmux set-status agent "backender" --color "#34c759"           # green pill
cmux set-status task "working" --color "#ff9f0a"              # orange pill
cmux set-status db "migrations applied" --color "#FFD60A"     # yellow pill
cmux set-status telegram "connected" --color "#2AABEE"        # blue pill
cmux clear-status agent                                        # remove a status
cmux list-status                                               # show all status entries
cmux list-status --workspace workspace:2                       # for specific workspace
```

### Progress Bar
```bash
cmux set-progress 0.35 --label "Phase 3: 18/52"              # 35% with label
cmux set-progress 0.0 --label "Starting..."                   # empty bar
cmux set-progress 1.0 --label "Complete"                      # full bar
cmux clear-progress                                            # remove progress bar
```

### Log Panel
```bash
cmux log --level info --source pm -- "Launched ai-engineer"   # info log
cmux log --level success --source sync -- "Full sync complete" # success
cmux log --level error --source api -- "Connection refused"    # error
cmux log --level progress --source pm -- "Phase 3: 5/52"      # progress
cmux list-log --limit 20                                       # read recent logs
cmux list-log --limit 10 --workspace workspace:2              # logs from specific workspace
cmux clear-log                                                 # clear log panel
```

---

## 4. Sending Commands & Reading Output

### Send Text / Keys
```bash
cmux send "ls -la" --workspace workspace:2                    # type text into terminal
cmux send-key Enter --workspace workspace:2                   # press Enter
cmux send-key C-c --workspace workspace:2                     # Ctrl+C
cmux send-key C-d --workspace workspace:2                     # Ctrl+D (EOF)
```

### Read Terminal Output
```bash
cmux read-screen --lines 50                                   # last 50 lines, current
cmux read-screen --workspace workspace:2 --lines 100         # from specific workspace
cmux read-screen --workspace workspace:2 --scrollback         # full scrollback buffer
```

### Pipe Output
```bash
cmux pipe-pane --command "tee /tmp/agent-output.log"          # pipe pane output to file
```

---

## 5. Browser Panels

### Open & Navigate
```bash
cmux browser open "http://localhost:5173"                     # browser in current workspace
cmux browser open-split "http://localhost:8000/docs"          # browser in new split
cmux browser goto "http://localhost:5173/dashboard"           # navigate existing browser
cmux browser back                                              # go back
cmux browser reload                                            # refresh page
cmux browser url                                               # get current URL
```

### Interact with Page
```bash
cmux browser snapshot                                          # get page DOM snapshot
cmux browser snapshot --interactive                            # interactive elements only
cmux browser screenshot --out /tmp/page.png                   # screenshot
cmux browser click "#login-button"                            # click element
cmux browser fill "#search-input" "query text"                # fill input
cmux browser type "#editor" "hello world"                     # type into element
cmux browser eval "document.title"                            # run JavaScript
cmux browser wait --selector ".loaded"                        # wait for element
cmux browser get text --selector ".result"                    # get element text
```

---

## 6. Notifications
```bash
cmux notify --title "Build Done" --body "Frontend compiled successfully"
cmux notify --title "Agent Failed" --subtitle "backender" --body "Missing dependency: httpx"
cmux list-notifications
cmux clear-notifications
```

---

## 7. Windows (groups of workspaces)
```bash
cmux list-windows
cmux current-window
cmux new-window                                                # new window
cmux focus-window --window window:2
cmux close-window --window window:2
cmux move-workspace-to-window --workspace workspace:3 --window window:2
cmux next-window                                               # cycle windows
cmux previous-window
```

---

## 8. Markdown Viewer
```bash
cmux markdown docs/plan/progress.md                           # open formatted markdown panel with live reload
```

---

## 9. Agent Orchestration via `pm-cmux.sh`

The PM helper library at `scripts/pm-cmux.sh` wraps cmux for agent management. Use it when orchestrating agent work across workspaces.

### Agent Color Map

| Agent | Color | Emoji |
|-------|-------|-------|
| pm | `#007AFF` | `🔵` |
| backender | `#34c759` | `🟢` |
| frontender | `#5AC8FA` | `🔷` |
| db-architect | `#FFD60A` | `🟡` |
| ai-engineer | `#FF2D92` | `🟣` |
| channel-engineer | `#FF9500` | `🟠` |
| test-writer | `#FFFFFF` | `⚪` |
| security-auditor | `#FF3B30` | `🔴` |

### Full Orchestration Workflow

```bash
# 1. Initialize PM session
source scripts/pm-cmux.sh && pm_init

# 2. Launch agents in parallel workspaces
ws_ai=$(pm_launch_agent ai-engineer "Phase 3.1 — Embedder" "Create services/rag/embedder.py...")
ws_be=$(pm_launch_agent backender "Phase 3.8 — Knowledge API" "Create backend/app/api/v1/knowledge.py...")

# 3. Monitor
pm_dashboard                         # full overview
pm_read_agent "$ws_ai" 50           # read ai-engineer output
pm_list_agents                       # sidebar status summary

# 4. Update status as work progresses
pm_update_agent ai-engineer working "$ws_ai"
pm_update_agent backender working "$ws_be"

# 5. Track phase progress
pm_phase_progress 3 10 52           # Phase 3: 10/52

# 6. On completion
pm_agent_done ai-engineer "$ws_ai"   # sets ✅, sends notification
pm_agent_done backender "$ws_be"

# 7. Cleanup
pm_cleanup_agent ai-engineer "$ws_ai"
pm_cleanup_agent backender "$ws_be"
```

### Direct CLI Usage (without sourcing)

```bash
scripts/pm-cmux.sh init
scripts/pm-cmux.sh launch ai-engineer "Phase 3.1" "Create embedder..."
scripts/pm-cmux.sh update ai-engineer working workspace:5
scripts/pm-cmux.sh done ai-engineer workspace:5
scripts/pm-cmux.sh failed ai-engineer "Error message" workspace:5
scripts/pm-cmux.sh read workspace:5 50
scripts/pm-cmux.sh dashboard
scripts/pm-cmux.sh cleanup ai-engineer workspace:5
scripts/pm-cmux.sh phase 3 18 52
scripts/pm-cmux.sh progress 0.65 "v1 MVP: 65%"
```

---

## 10. Agent Monitoring — Automatic Completion Detection

After launching an agent, **always** set up background monitoring to detect when it finishes. Never wait for the user to report completion.

### Method 1: Signal-Based (Preferred)

The Stop hook in `~/.claude/hooks/cmux-notify.sh` reads `$PM_SIGNAL_NAME` (set by `pm_launch_agent`) and sends `cmux wait-for --signal agent-done-{workspace:N}`. PM waits for this signal.

```bash
# Launch agent — returns workspace ref (e.g., "workspace:8")
ws=$(pm_launch_agent ai-engineer "Task Name" "prompt...")

# Wait for completion signal (blocking, with timeout)
cmux wait-for "agent-done-${ws}" --timeout 600
# Returns when agent's Stop hook fires

source scripts/pm-cmux.sh
pm_agent_done ai-engineer "$ws"
```

For multiple agents, wait in parallel background tasks:

```bash
ws1=$(pm_launch_agent ai-engineer "Task A" "...")
ws2=$(pm_launch_agent backender "Task B" "...")

# Wait for both via signals
cmux wait-for "agent-done-${ws1}" --timeout 600 &
cmux wait-for "agent-done-${ws2}" --timeout 600 &
wait  # blocks until both finish
```

### How It Works

1. Agent finishes → Claude Code fires `Stop` hook
2. `~/.claude/hooks/cmux-notify.sh` runs `cmux wait-for --signal agent-done-{CMUX_WORKSPACE_ID}`
3. PM's background `cmux wait-for "agent-done-workspace:N"` unblocks
4. PM gets task-notification → proceeds to next batch

### Troubleshooting

If `wait-for` times out, the agent may have crashed without triggering Stop hook. Check manually:
```bash
cmux read-screen --workspace "$ws_id" --lines 20   # read terminal output
```

### On Completion — Immediate Actions

```bash
# 1. Mark done
pm_agent_done agent-name "$ws_id"

# 2. Verify output (quick ls/import check)
ls -la /path/to/output/*.py

# 3. Update progress
pm_phase_progress 3 25 52

# 4. Cleanup workspace
pm_cleanup_agent agent-name "$ws_id"

# 5. Launch next batch immediately — don't wait for user
ws_next=$(pm_launch_agent next-agent "Next Task" "prompt...")
```

### Monitoring Multiple Agents in Parallel

**Preferred: signal-based**
```bash
ws1=$(pm_launch_agent ai-engineer "Task A" "...")
ws2=$(pm_launch_agent backender "Task B" "...")

# Wait for both via signals (parallel waits)
cmux wait-for "agent-done-${ws1}" --timeout 600 &
cmux wait-for "agent-done-${ws2}" --timeout 600 &
wait  # returns when both agents finish
echo "ALL DONE"
```


---

## 11. Common Layout Recipes

### Dev Layout: editor + terminal + browser
```bash
cmux rename-workspace "dev: agency"
cmux new-split right                                           # terminal on right
cmux browser open-split "http://localhost:5173"               # browser below
cmux set-status dev "ready" --color "#34c759"
```

### Monitoring Layout: logs + status
```bash
cmux rename-workspace "monitor: services"
cmux new-split right                                           # second terminal
cmux new-split down                                            # third below right
cmux send --surface surface:2 "docker compose -f docker-compose.dev.yml logs -f backend"
cmux send-key --surface surface:2 Enter
cmux send --surface surface:3 "docker compose -f docker-compose.dev.yml logs -f rag"
cmux send-key --surface surface:3 Enter
```

### Parallel Agents Layout (PM view)
```bash
source scripts/pm-cmux.sh && pm_init
ws1=$(pm_launch_agent ai-engineer "RAG Core" "...")
ws2=$(pm_launch_agent backender "Knowledge API" "...")
ws3=$(pm_launch_agent test-writer "Smoke Tests" "...")
# PM workspace shows all agent statuses in sidebar
# Switch between: cmux select-workspace --workspace $ws1
```

---

## Best Practices

1. **Always `2>/dev/null`** on cmux calls — gracefully handle socket issues
2. **Check availability first** before running sequences of cmux commands
3. **Use `--workspace`** to target specific workspaces; without it, commands target current
4. **Status pills are key-value** — use descriptive keys (`agent`, `task`, `db`, `sync`) not generic ones
5. **Color consistently** — stick to the agent color map for familiarity
6. **Log important events** — launches, completions, errors. Logs persist in the sidebar
7. **Notifications for completion/failure** — `cmux notify` triggers macOS notification center
8. **Read before you send** — use `read-screen` to check terminal state before sending commands
9. **Clean up workspaces** — close done agent workspaces to avoid clutter
10. **Progress bar = phase-level** — don't update on every micro-task, use it for phase/milestone tracking
