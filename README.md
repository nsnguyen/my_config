# my_config

My portable shell toolkit — a set of `fzf`-powered git/file helpers and aliases
that I carry between machines. One file (`functions.zsh`), one command to install.

## Install (no clone needed)

On a machine with the [GitHub CLI](https://cli.github.com) authed (`gh auth login`):

```sh
gh api -H "Accept: application/vnd.github.raw" \
  repos/nsnguyen/my_config/contents/install.sh | bash
```

The installer:
1. drops `functions.zsh` into `~/.config/zsh/`,
2. installs the dependencies via `brew bundle` (the `Brewfile`),
3. adds a `source` line to `~/.zshrc` (idempotent).

Then `source ~/.zshrc` (or open a new terminal) and run `help`.

> If you ever make this repo **public**, the install simplifies to:
> `curl -fsSL https://raw.githubusercontent.com/nsnguyen/my_config/main/install.sh | bash`

## What you get

Run `help` any time to see this list.

| Command | Does |
|---------|------|
| `ff`    | Fuzzy-find a file (preview) → open it **and its project** in VS Code |
| `fa`    | Live ripgrep content search, grouped by file → open match in VS Code |
| `ffg`   | Fuzzy-browse git commits (preview; `ctrl-y` copies hash) |
| `gg`    | Diff viewer for the current branch + open GitHub PRs |
| `gc`    | Checkout a recent branch with a log preview |
| `gt`    | Pretty git log graph |
| `ls/ll/la/lt` | `eza` listings (icons, git, tree) |
| `cat`   | `bat` (syntax-highlighted) |
| `reload`/`zshrc` | reload / view `~/.zshrc` |

## Dependencies

`fzf`, `ripgrep`, `bat`, `eza`, `fd`, `gh`, `git-delta`, and the VS Code `code`
CLI. All captured in the `Brewfile` and installed for you.

## Secrets / machine-specific config

This repo is intentionally **secrets-free**. API keys and per-machine bits live
in `~/.zshrc.local` (gitignored, never shared). Keep it that way.

## Editing

On my main machine `~/.config/zsh/functions.zsh` is a symlink to this repo, so
edits here are live. After changing something: `git commit && git push`, then on
other machines re-run the install one-liner.
