#!/usr/bin/env bash
# my_config — one-line install (no clone, no gh needed; this repo is public):
#
#   curl -fsSL https://raw.githubusercontent.com/nsnguyen/my_config/main/install.sh | bash
#
# Safe by design: backs up ~/.zshrc before touching it, and warns about any
# function/alias names it's about to override on this machine.
set -euo pipefail

BASE="https://raw.githubusercontent.com/nsnguyen/my_config/main"
ZDIR="$HOME/.config/zsh"
RC="$HOME/.zshrc"

say()   { printf '\033[1;36m→\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m⚠\033[0m %s\n' "$1"; }
fetch() { curl -fsSL "$BASE/$1"; }

mkdir -p "$ZDIR"
say "Installing functions.zsh -> $ZDIR/functions.zsh"
fetch functions.zsh > "$ZDIR/functions.zsh"

if command -v brew >/dev/null 2>&1; then
  say "Installing dependencies (brew bundle)"
  tmp="$(mktemp)"; fetch Brewfile > "$tmp"; brew bundle --file="$tmp" || true; rm -f "$tmp"
else
  warn "Homebrew not found — install it from https://brew.sh, then re-run."
fi

if grep -qF '.config/zsh/functions.zsh' "$RC" 2>/dev/null; then
  say "~/.zshrc already sources functions.zsh — refreshed it, left ~/.zshrc untouched."
else
  # --- pre-flight: which names will we override on THIS machine? ---
  if command -v zsh >/dev/null 2>&1; then
    set +e
    ours="$( { grep -oE '^[[:space:]]*function [A-Za-z0-9_]+' "$ZDIR/functions.zsh" | awk '{print $NF}'
               grep -oE '^[[:space:]]*alias [A-Za-z0-9_-]+='   "$ZDIR/functions.zsh" | sed -E 's/.*alias ([^=]+)=/\1/'; } | sort -u )"
    # load this machine's current config (without our toolkit) and list its names
    existing="$(POWERLEVEL9K_INSTANT_PROMPT=off zsh -ic 'print -l -- ${(k)aliases} ${(k)functions}' 2>/dev/null | sort -u)"
    clash="$(comm -12 <(printf '%s\n' "$ours") <(printf '%s\n' "$existing"))"
    set -e
    if [ -n "$clash" ]; then
      warn "These names already exist here and will be overridden (yours load last, so they win):"
      printf '%s\n' "$clash" | sed 's/^/        /'
      echo  "        ↑ your existing definitions stay in ~/.zshrc untouched — just shadowed."
    fi
  fi

  # --- timestamped backup, then wire in ---
  if [ -f "$RC" ]; then
    bk="$RC.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$RC" "$bk"; say "Backed up ~/.zshrc -> $(basename "$bk")"
  fi
  printf '\n# my_config dev toolkit\n[ -f ~/.config/zsh/functions.zsh ] && source ~/.config/zsh/functions.zsh\n' >> "$RC"
  say "Wired into ~/.zshrc"
fi

say "Done. Run:  source ~/.zshrc   then try:  help"
