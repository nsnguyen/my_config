#!/usr/bin/env bash
# my_config — one-line install (no clone, no gh needed; this repo is public):
#
#   curl -fsSL https://raw.githubusercontent.com/nsnguyen/my_config/main/install.sh | bash
#
set -euo pipefail

BASE="https://raw.githubusercontent.com/nsnguyen/my_config/main"
ZDIR="$HOME/.config/zsh"

say()   { printf '\033[1;36m→\033[0m %s\n' "$1"; }
fetch() { curl -fsSL "$BASE/$1"; }

mkdir -p "$ZDIR"
say "Installing functions.zsh -> $ZDIR/functions.zsh"
fetch functions.zsh > "$ZDIR/functions.zsh"

if command -v brew >/dev/null 2>&1; then
  say "Installing dependencies (brew bundle)"
  tmp="$(mktemp)"; fetch Brewfile > "$tmp"; brew bundle --file="$tmp" || true; rm -f "$tmp"
else
  echo "  ! Homebrew not found — install it from https://brew.sh, then re-run."
fi

if ! grep -qF '.config/zsh/functions.zsh' "$HOME/.zshrc" 2>/dev/null; then
  printf '\n# my_config dev toolkit\n[ -f ~/.config/zsh/functions.zsh ] && source ~/.config/zsh/functions.zsh\n' >> "$HOME/.zshrc"
  say "Wired into ~/.zshrc"
else
  say "~/.zshrc already sources functions.zsh"
fi

say "Done. Run:  source ~/.zshrc   then try:  help"
