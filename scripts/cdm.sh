#!/bin/bash
# CDM - Claude Dangerous Mode
# Launches claude with --dangerously-skip-permissions and cmux workspace setup

DIR="${1:-$(pwd)}"

if [ ! -d "$DIR" ]; then
  echo "Directory not found: $DIR"
  exit 1
fi

# Check cmux installation
if ! command -v cmux &>/dev/null; then
  echo "cmux is not installed."
  echo "Install it with: brew install cmux"
  echo "More info: https://cmux.com"
  exit 1
fi

# Setup cmux workspace if available
if [ -S "${CMUX_SOCKET_PATH:-/tmp/cmux.sock}" ]; then
  DIRNAME=$(basename "$DIR")
  cmux rename-workspace "claude: $DIRNAME" 2>/dev/null
  cmux set-status claude "starting" --color "#ff9f0a" 2>/dev/null
  cmux log --level info --source claude -- "Starting session in $DIRNAME" 2>/dev/null
fi

cd "$DIR" && claude --dangerously-skip-permissions --remote-control
