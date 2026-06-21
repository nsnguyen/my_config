#!/usr/bin/env bash
# my_config — one-line install (no manual clone needed).
#
#   gh api -H "Accept: application/vnd.github.raw" \
#     repos/nsnguyen/my_config/contents/install.sh | bash
#
# (If you make the repo public, you can use curl instead:)
#   curl -fsSL https://raw.githubusercontent.com/nsnguyen/my_config/main/install.sh | bash
set -euo pipefail

REPO="nsnguyen/my_config"
ZDIR="$HOME/.config/zsh"

say() { printf '\033[1;36m→\033[0m %s\n' "$1"; }

command -v gh >/dev/null 2>&1 || {
  echo "Need the GitHub CLI first:  brew install gh && gh auth login"; exit 1; }

raw() { gh api -H "Accept: application/vnd.github.raw" "repos/$REPO/contents/$1"; }

mkdir -p "$ZDIR"
say "Installing functions.zsh -> $ZDIR/functions.zsh"
raw functions.zsh > "$ZDIR/functions.zsh"

if command -v brew >/dev/null 2>&1; then
  say "Installing dependencies (brew bundle)"
  tmp="$(mktemp)"; raw Brewfile > "$tmp"; brew bundle --file="$tmp" || true; rm -f "$tmp"
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
