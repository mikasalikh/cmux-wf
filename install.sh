#!/bin/bash
# install.sh — Install cmux-wf and its dependencies
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${1:-$HOME/.local/bin}"

echo "=== cmux-wf installer ==="
echo ""

# ── Check / install Homebrew ──────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Homebrew is not installed."
  read -rp "Install Homebrew? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
  else
    echo "Homebrew is required. Aborting."
    exit 1
  fi
fi
echo "✓ Homebrew: $(brew --version | head -1)"

# ── Check / install cmux ─────────────────────────────────────────
if ! command -v cmux &>/dev/null; then
  echo "cmux is not installed."
  read -rp "Install cmux via brew? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    brew install cmux
  else
    echo "cmux is required. Aborting."
    exit 1
  fi
fi
echo "✓ cmux: $(cmux --version 2>/dev/null)"

# ── Check / install Claude Code CLI ──────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "Claude Code CLI is not installed."
  read -rp "Install Claude Code via brew? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    brew install --cask claude-code
  else
    echo "Claude Code is required. Aborting."
    exit 1
  fi
fi
echo "✓ claude: $(claude --version 2>/dev/null | head -1)"

# ── Install scripts ──────────────────────────────────────────────
echo ""
echo "Installing scripts to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"

for script in cdm.sh pm-cmux.sh; do
  cp "$SCRIPT_DIR/scripts/$script" "$INSTALL_DIR/$script"
  chmod +x "$INSTALL_DIR/$script"
  echo "  → $INSTALL_DIR/$script"
done

# Symlink cdm without .sh extension for convenience
ln -sf "$INSTALL_DIR/cdm.sh" "$INSTALL_DIR/cdm"
echo "  → $INSTALL_DIR/cdm (symlink)"

# ── Check PATH ───────────────────────────────────────────────────
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo "⚠ $INSTALL_DIR is not in your PATH."
  echo "Add this to your ~/.zshrc:"
  echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo ""
echo "Done! Run 'cdm' to start a Claude session with cmux."
