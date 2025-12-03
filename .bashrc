#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias ls='ls -la --color=auto'
alias grep='grep --color=auto'
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
PS1='[\u@\h \W]\$ '
## Handy Utilities
alias update="sudo pacman -Syu && sudo paru -Syu && pacman -Qqen > ~/.arch/pkglist.txt && pacman -Qqem > ~/.arch/aurlist.txt"
alias refresh="source ~/.bashrc"
alias r="refresh"
alias c="clear"
## Cargo
alias cb="cargo build"
alias cr="cargo run"
## Docker
alias dcu="docker compose up"
alias dcd="docker compose down"
## Repositories
alias op='cd ~/Code/projects/optio-prospera'
## Git Shortcuts
alias ga='git add'
alias gcm='git commit'
alias gf='git fetch'
alias gfgp='git fetch && git pull'
alias gs='git status'
alias gb='git branch'
alias glg='git log --graph'
alias gp='git push origin $(git rev-parse --abbrev-ref HEAD)' # pushes to current branch without having to set upstream 
alias gd='git diff'
alias gc='git checkout $(git branch | fzf)' # fuzzy file finder for easily switching branches
alias gu='git reset --soft HEAD~1'
## Code Tools
alias read-code="rg --color=always --line-number --no-heading --smart-case \"\" | fzf --ansi --delimiter : --preview 'bat --color=always --highlight-line {2} {1}' --preview-window right:50%:wrap"

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Local Bin
export PATH="$HOME/.local/bin:$PATH"

# Kiro Shell Integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"

# AWS CLI default profile
export AWS_PROFILE=op-jacques-admin
