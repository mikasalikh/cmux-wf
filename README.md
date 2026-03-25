# cmux-wf

Scripts and Claude Code skill for orchestrating [Claude Code](https://claude.ai) workflows inside [cmux](https://cmux.com) — a terminal multiplexer with sidebar status, logs, notifications, and workspace management.

**[Русская версия](README_RU.md)**

---

## 📦 What's Included

```
cmux-wf/
├── install.sh                          # Installer with dependency checks
├── prompts/
│   └── pm.md                           # PM prompt — orchestrator instructions
├── scripts/
│   ├── cdm.sh                          # Claude Dangerous Mode — quick launcher
│   └── pm-cmux.sh                      # PM orchestrator — agent management
└── .claude/
    └── skills/
        └── cmux/
            └── SKILL.md                # Claude Code skill — full cmux API reference
```

| Component | Purpose |
|---|---|
| `cdm.sh` | Launch Claude Code with `--dangerously-skip-permissions` and auto-configured cmux workspace |
| `pm-cmux.sh` | PM orchestrator — manage Claude agents across cmux workspaces |
| `prompts/pm.md` | PM prompt — Claude analyzes the project and determines agents and tasks on its own |
| `.claude/skills/cmux/` | Claude Code skill — full cmux API knowledge |

---

## 🔧 Requirements

| Dependency | Purpose | Install |
|---|---|---|
| [Homebrew](https://brew.sh) | Package manager | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| [cmux](https://cmux.com) | Terminal multiplexer | `brew install cmux` |
| [Claude Code](https://claude.ai) | CLI for Claude | `brew install --cask claude-code` |
| zsh | Required for `pm-cmux.sh` | Built into macOS |
| bc | Progress calculation | Built into macOS |

---

## ⚡ Installation

```bash
git clone https://github.com/mikasalikh/cmux-wf.git
cd cmux-wf
./install.sh
```

The installer interactively checks each dependency and offers to install missing ones:

1. **Homebrew** — offers to install if not found
2. **cmux** — `brew install cmux`
3. **Claude Code** — `brew install --cask claude-code`
4. Copies scripts to `~/.local/bin` (or a specified directory)
5. Creates a `cdm` symlink for quick access

Install to a different directory:

```bash
./install.sh ~/my-scripts
```

---

## 🎯 Quick Start — PM Orchestrator

The fastest way to use cmux-wf — launch Claude as a PM orchestrator. It will analyze your project, determine the right agents, and distribute work across cmux workspaces.

### Step 0 — Prepare Project Documentation

The PM orchestrator works from your project docs. The better the project is documented, the more precise the planning and task distribution will be.

> [!IMPORTANT]
> Make sure key documents exist in the project before launching the orchestrator. Without them PM will guess — with them it will act precisely.

Recommended minimum:

| Document | Describes | Example |
|---|---|---|
| **PRD** | Product requirements, user stories, acceptance criteria | `docs/prd.md` |
| **Architecture** | System components, connections, data flow | `docs/architecture.md` |
| **Tech Stack** | Languages, frameworks, databases, infrastructure | `docs/stack.md` or in README |
| **Design / UI** | Mockups, wireframes, UI kit, Figma links | `docs/design.md` |
| **API Contracts** | Endpoints, request/response formats | `docs/api.md` or OpenAPI spec |
| **DB Schema** | Tables, relations, indexes | `docs/database.md` |

Not all are required — but each document improves agent output quality. PM uses them to craft precise prompts for each agent.

### Step 1 — Copy cmux-wf into Your Project

```bash
cp -r /path/to/cmux-wf/.claude/ ~/your-project/.claude/
cp -r /path/to/cmux-wf/prompts/ ~/your-project/prompts/
```

> [!NOTE]
> Claude Code automatically detects the `cmux` skill and gains workspace, panes, status, and log management capabilities. If Claude Code is already running — restart the session for the skill to load.

### Step 2 — Launch Claude in cmux

```bash
cd ~/your-project
cdm                        # or: cdm ~/your-project
```

> [!CAUTION]
> `cdm` launches Claude with `--dangerously-skip-permissions` — full access to filesystem, shell, and network without confirmations. See [Security](#-security) for details.

### Step 3 — Give the PM a Task

In the Claude session, type:

```
Read prompts/pm.md — this is your instruction as a PM orchestrator.
Task: <describe what needs to be done>
```

### Task Examples

```
# New feature
Task: Add OAuth2 authentication — backend API + frontend forms + tests.

# Refactoring
Task: Migrate the monolithic API to a modular structure. Split by domain.

# Full MVP
Task: Build an MVP chatbot with RAG — FastAPI backend, React frontend,
pgvector store. Break into phases, launch agents in parallel.

# Frontend with browser
Task: Redesign the dashboard — new layout, charts, filters.
Open http://localhost:5173 in cmux browser and verify results visually.

# E2E with browser
Task: Implement a registration form and test it via cmux browser —
fill fields, submit, verify redirect and data in the database.
```

### What Happens

1. Claude reads `prompts/pm.md` and becomes a PM orchestrator
2. Analyzes your project — stack, structure, dependencies
3. Breaks the task into phases and subtasks, creates `progress.md`
4. Launches agents in separate cmux workspaces via `pm-cmux.sh`
5. Monitors progress, reacts to failures, launches next phases
6. You see all agent statuses in the cmux sidebar in real time

> [!TIP]
> You can watch each agent's work by switching between cmux workspaces. PM sees everything via `pm_dashboard` and `pm_read_agent`.

---

## 📖 Reference — `pm-cmux.sh`

PM orchestrator for managing Claude agents via cmux workspaces. Works as a library (source) and as a CLI.

### As a Library (zsh)

```zsh
source scripts/pm-cmux.sh

# 1. Initialize
pm_init

# 2. Launch agents — each gets its own workspace
ws_be=$(pm_launch_agent backender "API Scaffold" "Create FastAPI app skeleton...")
ws_ai=$(pm_launch_agent ai-engineer "Embedder" "Create RAG embedder service...")

# 3. Update statuses
pm_update_agent backender working "$ws_be"
pm_update_agent ai-engineer working "$ws_ai"

# 4. Progress
pm_set_progress 0.35 "Phase 1: 15/42 tasks"
pm_phase_progress 1 15 42

# 5. Monitor
pm_dashboard                        # full overview
pm_read_agent "$ws_be" 100          # read agent output without switching

# 6. Completion
pm_agent_done backender "$ws_be"    # ✅ + notification
pm_agent_failed ai-engineer "Timeout" "$ws_ai"  # ❌ + notification

# 7. Cleanup
pm_cleanup_agent backender "$ws_be"
```

### As CLI

```bash
pm-cmux.sh init
pm-cmux.sh launch backender "API Scaffold" "Create FastAPI app..."
pm-cmux.sh update backender working
pm-cmux.sh done backender
pm-cmux.sh failed ai-engineer "Timeout"
pm-cmux.sh progress 0.65 "v1 MVP: 65%"
pm-cmux.sh phase 3 18 52
pm-cmux.sh read workspace:5 50
pm-cmux.sh dashboard
pm-cmux.sh cleanup backender workspace:5
pm-cmux.sh help
```

### 🎨 Built-in Agents

| Agent | Color | Role |
|---|---|---|
| pm | 🔵 `#007AFF` | PM orchestrator |
| backender | 🟢 `#34c759` | Backend development |
| frontender | 🔷 `#5AC8FA` | Frontend development |
| db-architect | 🟡 `#FFD60A` | Database architecture |
| ai-engineer | 🟣 `#FF2D92` | AI/ML integrations |
| channel-engineer | 🟠 `#FF9500` | Communication channels |
| test-writer | ⚪ `#FFFFFF` | Tests |
| security-auditor | 🔴 `#FF3B30` | Security audit |

### 📊 Agent Statuses

| Status | Meaning |
|---|---|
| ⏳ starting | Agent is launching |
| ⚡ working | Agent is working |
| 💤 waiting | Waiting for input or dependency |
| 🔍 reviewing | Code review |
| ✅ done | Completed successfully |
| ❌ failed | Completed with error |
| 🚫 blocked | Blocked |

---

### 🧠 Claude Code Skill — cmux

The skill `.claude/skills/cmux/SKILL.md` gives Claude Code full knowledge of the cmux API. When installed, Claude can independently:

- Create and manage workspaces and split panes
- Set statuses and progress in the sidebar
- Send commands to terminals in other workspaces
- Read agent output via `read-screen`
- Open and interact with the browser
- Send notifications

> [!TIP]
> The skill activates automatically when the task involves workspace management or agent orchestration.

### 🌐 Built-in Browser

cmux has a built-in browser right in the terminal — Claude can open pages, click elements, fill forms, take screenshots, and execute JavaScript. Great for interactive frontend development and testing without context switching:

```bash
cmux browser open-split "http://localhost:3000"         # browser in a split
cmux browser click "#submit-btn"                        # click an element
cmux browser fill "#email" "test@example.com"           # fill a form field
cmux browser screenshot --out /tmp/page.png             # screenshot
cmux browser eval "document.title"                      # execute JS
```

---

## ✅ Best Practices

### 🏗️ Workflow

- **One agent — one workspace.** Keeps logs, statuses, and output isolated
- **`pm_init` before launching agents** — initializes the PM workspace
- **Update statuses** — cmux sidebar shows all agent states in real time
- **`pm_dashboard` for overview** — shows workspaces, statuses, and recent logs
- **Clean up finished workspaces** — `pm_cleanup_agent` closes the workspace and removes the status

### 🖥️ Working with cdm

- Run `cdm` from the project root — Claude Code will get the right context
- `--remote-control` allows programmatic session control via cmux

### 📡 Agent Monitoring

- **`pm_read_agent`** — read agent output without switching workspaces
- **Pass a reason to `pm_agent_failed`** — it will appear in the log and macOS notification
- **`pm_set_progress` for milestones** — don't update on every micro-task
- **Signal-based monitoring** for automatic agent completion detection (see skill for details)

### ⚙️ cmux Commands in Scripts

- **Always `2>/dev/null`** on cmux calls — graceful handling when the socket is unavailable
- **Check availability** before running command sequences: `command -v cmux &>/dev/null`
- **`--workspace`** to target a specific workspace; without it, commands target the current one
- **Use colors consistently** — stick to the agent color map

---

## 🛑 Security

> [!CAUTION]
> **`--dangerously-skip-permissions`**
>
> This flag **completely disables** the Claude Code confirmation system.
> Claude gets unrestricted access to the filesystem, shell, and network.
>
> | | |
> |---|---|
> | 🔴 **Prohibited** | Production servers, shared machines, CI/CD pipelines |
> | 🟡 **Use with caution** | Local development with unfamiliar code |
> | 🟢 **Acceptable** | Isolated local environment, trusted projects |
>
> **You bear full responsibility for all Claude actions in this mode.**

> [!WARNING]
> - Agent prompt files are created in `/tmp` — do not pass sensitive data via prompts
> - cmux socket (`/tmp/cmux.sock`) is accessible to all local processes — restrict machine access

