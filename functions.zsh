# ============================================================================
#  functions.zsh - portable dev toolkit (fzf-powered git/file helpers + aliases)
#  Source of truth: github.com/nsnguyen/my_config  ->  ~/.config/zsh/functions.zsh
#  Deps: fzf ripgrep bat eza fd gh git-delta + the `code` CLI (see Brewfile)
#  Machine-specific bits (secrets, claude-mem) live in ~/.zshrc.local instead.
# ============================================================================

# Show all aliases and their descriptions
function show_aliases() {
  echo "\n📚 Available Aliases:\n"
  echo "Help & Config:"
  echo "  help                   - Show this help message"
  echo "  zshrc                  - View .zshrc file"
  echo "  reload                 - Reload .zshrc configuration"
  echo ""
  echo "Navigation:"
  echo "  dev                    - cd to ~/Documents/dev"
  echo "  notes                  - Open notes in VS Code"
  echo ""
  echo "eza (Modern ls):"
  echo "  ls                     - List with icons, directories first"
  echo "  ll, la                 - Detailed list with git status"
  echo "  lt                     - Tree view (3 levels, respects .gitignore)"
  echo ""
  echo "Fuzzy Finders (fzf):"
  echo "  ff                     - Fuzzy find files (opens in VS Code)"
  echo "  fa                     - Fuzzy search file contents (opens in VS Code)"
  echo "  ffg                    - Fuzzy find git commits"
  echo "  gg                     - Git diff viewer (PRs and branches)"
  echo "  gc                     - Checkout git branch with preview"
  echo "  gt                     - Pretty git log graph"
  echo ""
  echo "cmux:"
  echo "  cct                    - Launch cmux claude-teams"
  echo ""
}

# Fuzzy find git commits with preview
function fuzzy_find_git_commit() {
  git log \
    --color=always \
    --format="%C(cyan)%h %C(blue)%ar%C(auto)%d %C(yellow)%s %C(black)%ae" "$@" |
  fzf -i -e +s \
    --reverse \
    --tiebreak=index \
    --no-multi \
    --ansi \
    --nth=2.. \
    --preview="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always %'" \
    --preview-window='right:60%:wrap' \
    --bind shift-up:preview-page-up,shift-down:preview-page-down \
    --bind "ctrl-y:execute-silent(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | pbcopy)+abort" \
    --bind "enter:execute(echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R')"
}

# Fuzzy search file contents (ripgrep), grouped by file.
# Each file shows once as a magenta header, with its matching "line  content"
# indented underneath. Enter opens the highlighted match in VS Code (on a header
# row it opens that file's first match). Usage: fa  |  fa <term> (pre-fills box).
function fuzzy_search_content() {
  if ! command -v rg &> /dev/null; then
    echo "Please install ripgrep for interactive content search: brew install ripgrep"
    return 1
  fi

  # rg emits "file:line:content". awk reprints the path as a header when it
  # changes, indents each match, strips color from file/line, and appends hidden
  # \t<file>\t<line> fields that fzf uses for the preview ({2}/{3}) and to open.
  local RELOAD='[ -n {q} ] && rg --color=always --line-number --no-heading --with-filename --smart-case --glob "!.git" --glob "!node_modules" --glob "!__pycache__" --glob "!.idea" --glob "!.vscode" --glob "!graphify-out" --glob "!.DS_Store" --glob "!*.pyc" --glob "!*.swp" -- {q} 2>/dev/null | awk '\''BEGIN{e=sprintf("%c",27);esc=e"\\[[0-9;]*m";m=e"[1;35m";d=e"[38;5;248m";r=e"[0m"}{p=index($0,":");f=substr($0,1,p-1);s=substr($0,p+1);k=index(s,":");l=substr(s,1,k-1);c=substr(s,k+1);gsub(esc,"",f);gsub(esc,"",l);if(f!=pv){print m f r "\t" f "\t" l;pv=f}printf "  %s%4s%s  %s\t%s\t%s\n", d, l, r, c, f, l}'\'' || true'

  : | fzf -i \
    --ansi \
    --disabled \
    --reverse \
    --delimiter='\t' \
    --with-nth=1 \
    --query="${1:-}" \
    --prompt 'Search> ' \
    --header 'Type to search file contents | Enter: open in VS Code | Esc: quit' \
    --bind "start:reload:$RELOAD" \
    --bind "change:reload:$RELOAD" \
    --bind "enter:become([ -n {2} ] && code --goto {2}:{3})" \
    --preview 'if command -v bat &> /dev/null; then bat --theme="Monokai Extended Bright" --color=always --style=numbers --highlight-line {3} {2} 2>/dev/null; else cat -n {2} 2>/dev/null; fi' \
    --preview-window='right:60%:wrap:+{3}-/2' \
    --bind shift-up:preview-page-up,shift-down:preview-page-down \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --color='fg:#f8f8f2,fg+:#f8f8f2,bg+:#49483e,hl:#66d9ef,hl+:#a1efe4,info:#a6e22e,prompt:#f92672,pointer:#f92672,marker:#e6db74,spinner:#ae81ff,header:#75715e'
}

# Fuzzy find files with preview (Sublime Text style)
function fuzzy_find_file() {
  find . -type f \
    ! -path "*/\.git/*" \
    ! -path "*/node_modules/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/\.idea/*" \
    ! -path "*/\.vscode/*" \
    ! -path "*/graphify-out/*" \
    ! -name ".DS_Store" \
    ! -name "*.pyc" \
    ! -name "*.swp" 2>/dev/null |
  sed 's|^\./||' |
  awk -F/ '{
    filename=$NF;
    path=$0;
    sub(/\/[^\/]+$/, "", path);
    if (path == "") path = ".";
    printf "%s \033[38;5;242m%s\033[0m\t%s\n", filename, path, $0;
  }' |
  sort |
  fzf -i -e \
    --reverse \
    --ansi \
    --with-nth=1 \
    --delimiter=$'\t' \
    --preview 'file=$(echo {} | awk "{print \$NF}"); if command -v bat &> /dev/null; then bat --theme="Monokai Extended Bright" --color=always --style=numbers --line-range :500 "$file"; else cat -n "$file" | head -500; fi' \
    --preview-window='right:60%:wrap' \
    --bind shift-up:preview-page-up,shift-down:preview-page-down \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --tiebreak=begin \
    --select-1 \
    --query="$1" \
    --color='fg:#f8f8f2,fg+:#f8f8f2,bg+:#49483e,hl:#66d9ef,hl+:#a1efe4,info:#a6e22e,prompt:#f92672,pointer:#f92672,marker:#e6db74,spinner:#ae81ff,header:#75715e' |
  awk '{print $NF}' |
  xargs -I {} code "$(git rev-parse --show-toplevel 2>/dev/null || echo .)" "{}"
}

# Checkout git branch with preview
function checkout_git_branch() {
  local selected_branch
  selected_branch=$(git branch --sort=-committerdate -a |
    fzf --reverse \
      --header 'Checkout Recent Branch' \
      --preview 'branch_name=$(echo {1} | sed "s#remotes/origin/##" | sed "s#^\*##" | xargs); git log --color=always --oneline --graph --date=short --pretty="format:%C(auto)%h %C(blue)%an %C(green)%ar %C(auto)%s" $branch_name -10' \
      --bind shift-left:preview-page-up,shift-right:preview-page-down |
    awk '{gsub(/(remotes\/origin\/|^\*? +)/, "", $0); print}')

  if [ -n "$selected_branch" ]; then
    if ! git show-ref --quiet --verify "refs/heads/$selected_branch" 2>/dev/null; then
      git switch -c "$selected_branch" 2>/dev/null || git checkout "$selected_branch"
    else
      git checkout "$selected_branch"
    fi
  fi
}

# Git diff viewer for PRs and branches
function git_diff_viewer() {
  # Auto-detect default branch
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [ -z "$default_branch" ]; then
    default_branch="main"
  fi

  local current_branch=$(git branch --show-current)
  local items=()

  # Add current branch if it has changes
  if [ -n "$current_branch" ] && [ "$current_branch" != "$default_branch" ]; then
    local file_count=$(git diff --name-only "$default_branch"...HEAD 2>/dev/null | wc -l | xargs)
    if [ "$file_count" -gt 0 ]; then
      items+=("current"$'\t'"$current_branch (no PR)"$'\t'"$file_count files")
    fi
  fi

  # Fetch open PRs from GitHub
  if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    while IFS=$'\t' read -r number title author date branch; do
      items+=("PR #$number"$'\t'"$title"$'\t'"@$author $date"$'\t'"$branch")
    done < <(gh pr list --limit 50 --json number,title,author,updatedAt,headRefName --jq '.[] | [.number, .title, .author.login, (.updatedAt | fromdateiso8601 | now - . | if . < 3600 then "\(. / 60 | floor)m ago" elif . < 86400 then "\(. / 3600 | floor)h ago" elif . < 604800 then "\(. / 86400 | floor)d ago" else "\(. / 604800 | floor)w ago" end), .headRefName] | @tsv' 2>/dev/null)
  fi

  if [ ${#items[@]} -eq 0 ]; then
    echo "No PRs or changes found."
    return
  fi

  # Display with fzf
  printf '%s\n' "${items[@]}" | \
  fzf -i -e \
    --reverse \
    --ansi \
    --delimiter=$'\t' \
    --with-nth=1,2,3 \
    --header 'Select branch/PR to view diff | Shift+↑↓ scroll | Ctrl+/ fullscreen | Esc quit' \
    --preview 'type=$(echo {} | cut -f1 | cut -d" " -f1); \
      if [ "$type" = "current" ]; then \
        branch="'"$current_branch"'"; \
        echo "📊 Comparing $branch vs '"$default_branch"'\n"; \
        git diff --stat --color=always "'"$default_branch"'...$branch" 2>/dev/null; \
        echo ""; \
        git diff --color=always "'"$default_branch"'...$branch" 2>/dev/null | \
        awk -v count=0 '\''
          /^diff --git/ {
            count++;
            file = $0;
            sub(/^diff --git a\//, "", file);
            sub(/ b\/.*$/, "", file);
            printf "\n\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n";
            printf "\033[1;33m📄 File %d:\033[0m \033[1;32m%s\033[0m\n", count, file;
            printf "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n";
          }
          {print}
        '\'' | if command -v delta &> /dev/null; then delta --side-by-side=never; else cat; fi; \
      else \
        pr_number=$(echo {} | cut -f1 | grep -o "[0-9]*"); \
        branch=$(echo {} | awk -F"\t" "{print \$NF}"); \
        echo "📊 PR #$pr_number: $branch vs '"$default_branch"'\n"; \
        gh pr diff "$pr_number" --color=always 2>/dev/null | \
        awk -v count=0 '\''
          /^diff --git/ {
            count++;
            file = $0;
            sub(/^diff --git a\//, "", file);
            sub(/ b\/.*$/, "", file);
            printf "\n\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n";
            printf "\033[1;33m📄 File %d:\033[0m \033[1;32m%s\033[0m\n", count, file;
            printf "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n";
          }
          {print}
        '\'' | if command -v delta &> /dev/null; then delta --side-by-side=never; else cat; fi; \
      fi' \
    --preview-window='right:70%:wrap' \
    --bind shift-up:preview-page-up,shift-down:preview-page-down \
    --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --bind "ctrl-y:execute-silent(echo {} | awk -F'\t' '{print \$NF}' | pbcopy)+abort" \
    --color='fg:#f8f8f2,fg+:#f8f8f2,bg+:#49483e,hl:#66d9ef,hl+:#a1efe4,info:#a6e22e,prompt:#f92672,pointer:#f92672,marker:#e6db74,spinner:#ae81ff,header:#75715e'
}

# --------------------------------- aliases ----------------------------------
# Help & config
alias help='show_aliases'
alias zshrc='bat ~/.zshrc || cat ~/.zshrc'
alias reload='source ~/.zshrc && echo "✓ .zshrc reloaded"'

# Navigation
alias dev="cd ~/Documents/dev"
alias notes="code ~/Documents/notes/."

# eza - modern ls replacement
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git --header'
alias la='ll'
alias lt='eza --tree --level=3 --icons --group-directories-first --git-ignore'

# fzf - fuzzy finder
alias ff='fuzzy_find_file'
alias fa='fuzzy_search_content'
alias ffg='fuzzy_find_git_commit'
alias gg='git_diff_viewer'
alias gc='checkout_git_branch'
alias gt="git log --graph --pretty=format:\"%C(yellow)%h%x09%Creset%C(cyan)%C(bold)%ad%Creset %C(yellow)%cn%Creset  %C(green)%Creset %s\" --date=default"

# docker
alias docker_prune_all="docker system prune -a"

# cat -> bat
if command -v bat > /dev/null; then
  alias cat='bat --theme="Dracula" --color=always --style=numbers'
elif command -v batcat > /dev/null; then
  alias cat='batcat --theme="Dracula" --color=always --style=numbers'
fi

# cmux
alias cct="cmux claude-teams"
