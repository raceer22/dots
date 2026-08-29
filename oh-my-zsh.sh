#!/usr/bin/env bash
# =============================================================================
#  Oh My Zsh — Full Setup Script for Fresh Ubuntu
#  Installs zsh, Oh My Zsh, top plugins, Powerlevel10k theme, and .zshrc
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR]${NC}   $*"; exit 1; }

# ── 1. System packages ───────────────────────────────────────────────────────
info "Updating apt and installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    zsh curl git wget unzip fontconfig \
    fzf bat fd-find ripgrep \
    build-essential python3-pip

# fd-find installs as 'fdfind' on Ubuntu; alias it
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
fi

success "System packages installed."

# ── 2. Nerd Font (MesloLGS — required for Powerlevel10k) ─────────────────────
install_nerd_font() {
    local FONT_DIR="$HOME/.local/share/fonts"
    local FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
    mkdir -p "$FONT_DIR"
    local fonts=(
        "MesloLGS%20NF%20Regular.ttf"
        "MesloLGS%20NF%20Bold.ttf"
        "MesloLGS%20NF%20Italic.ttf"
        "MesloLGS%20NF%20Bold%20Italic.ttf"
    )
    info "Downloading MesloLGS Nerd Font..."
    for f in "${fonts[@]}"; do
        local fname="${f//%20/ }"
        if [[ ! -f "$FONT_DIR/$fname" ]]; then
            wget -q "$FONT_URL/$f" -O "$FONT_DIR/$fname"
        fi
    done
    fc-cache -f "$FONT_DIR"
    success "Nerd Font installed. Set your terminal font to 'MesloLGS NF'."
}
install_nerd_font

# ── 3. Oh My Zsh ─────────────────────────────────────────────────────────────
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    warn "Oh My Zsh already installed at ~/.oh-my-zsh — skipping."
else
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ── 4. Theme: Powerlevel10k ───────────────────────────────────────────────────
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$ZSH_CUSTOM/themes/powerlevel10k"
    success "Powerlevel10k installed."
fi

# ── 5. Plugins ────────────────────────────────────────────────────────────────
declare -A PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
    ["zsh-you-should-use"]="https://github.com/MichaelAquilina/zsh-you-should-use"
    ["fzf-tab"]="https://github.com/Aloxaf/fzf-tab"
    ["zsh-bat"]="https://github.com/fdellwing/zsh-bat"
)

for plugin in "${!PLUGINS[@]}"; do
    dest="$ZSH_CUSTOM/plugins/$plugin"
    if [[ ! -d "$dest" ]]; then
        info "Installing plugin: $plugin"
        git clone --depth=1 "${PLUGINS[$plugin]}" "$dest"
        success "$plugin installed."
    else
        warn "$plugin already present — skipping."
    fi
done

# ── 6. Write .zshrc ───────────────────────────────────────────────────────────
ZSHRC="$HOME/.zshrc"
[[ -f "$ZSHRC" ]] && cp "$ZSHRC" "${ZSHRC}.bak.$(date +%s)" && warn "Backed up existing .zshrc"

info "Writing new .zshrc..."
cat > "$ZSHRC" << 'ZSHRC_EOF'
# =============================================================================
#  .zshrc — Oh My Zsh configuration
# =============================================================================

# ── Powerlevel10k instant prompt (keep at top) ────────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Oh My Zsh core ────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY HIST_REDUCE_BLANKS

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # case-insensitive

# ── Plugins ───────────────────────────────────────────────────────────────────
# NOTE: fzf-tab must come AFTER compinit but BEFORE zsh-syntax-highlighting
plugins=(
  # --- Core OMZ plugins ---
  git                     # git aliases (gst, gco, gp, gl…)
  gitignore               # gi <lang> → fetch .gitignore template
  sudo                    # press ESC twice to prepend sudo
  colorize                # syntax-highlight cat / less output
  colored-man-pages       # colour in man pages
  command-not-found       # suggest package on unknown command
  extract                 # `x archive.tar.gz` for any format
  z                       # jump to frecent dirs with `z <keyword>`
  cp                      # rsync-powered `cpv` with progress bar
  safe-paste              # prevent accidental multi-line paste exec
  magic-enter             # Enter on empty line runs `git status` / `ls`
  tmux                    # tmux aliases + auto-start option
  docker                  # Docker completions & aliases
  docker-compose          # docker compose aliases
  kubectl                 # k alias + completions
  npm                     # npm completions
  node                    # node version completions
  python                  # pyenv / virtualenv helpers
  pip                     # pip completions
  virtualenv              # show venv in prompt
  aws                     # AWS CLI completions
  terraform               # terraform completions & aliases
  systemd                 # sc-* shortcuts for systemctl
  ufw                     # ufw completions
  ssh-agent               # auto-start ssh-agent
  gpg-agent               # auto-start gpg-agent
  copypath                # `copypath` copies current dir to clipboard
  copyfile                # `copyfile <file>` copies file content
  dirhistory              # Alt+← / Alt+→ navigate dir history
  web-search              # `google foo` opens browser search
  jsontools               # pp_json, is_json helpers

  # --- Third-party plugins ---
  zsh-completions
  zsh-autosuggestions
  fzf-tab
  zsh-syntax-highlighting          # keep last among syntax plugins
  zsh-history-substring-search
  you-should-use
  zsh-bat
)

source "$ZSH/oh-my-zsh.sh"

# ── Plugin config ─────────────────────────────────────────────────────────────

# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086,bold"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
bindkey '^ ' autosuggest-accept          # Ctrl+Space to accept suggestion

# zsh-history-substring-search — bind AFTER syntax-highlighting
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=cyan,fg=black,bold'

# fzf-tab
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-min-height 20

# you-should-use
YSU_MESSAGE_POSITION="after"
YSU_MODE=ALL

# tmux — uncomment to auto-start in every terminal
# ZSH_TMUX_AUTOSTART=true

# ── fzf ───────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS='
  --height 40% --layout=reverse --border rounded
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Load fzf shell integration
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && \
    source /usr/share/doc/fzf/examples/completion.zsh

# ── Better ls with exa ────────────────────────────────────────────────────────
if command -v exa &>/dev/null; then
  alias ls='exa --icons --group-directories-first'
  alias ll='exa -lah --icons --group-directories-first --git'
  alias la='exa -a --icons --group-directories-first'
  alias lt='exa --tree --level=2 --icons'
  alias llt='exa --tree --level=3 --long --icons --git'
fi

# ── Better cat with bat ───────────────────────────────────────────────────────
if command -v bat &>/dev/null; then
  alias cat='bat --style=auto'
  alias catp='bat --style=plain'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat &>/dev/null; then
  alias cat='batcat --style=auto'
  alias catp='batcat --style=plain'
fi

# ── Handy aliases ─────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias wget='wget -c'                     # resume by default

alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
alias localip="ip -br a | awk '{print \$1, \$3}'"

alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
alias please='sudo $(fc -ln -1)'        # re-run last command with sudo

alias reload='source ~/.zshrc && echo "zshrc reloaded"'
alias zshconfig='${EDITOR:-nano} ~/.zshrc'
alias p10kconfig='${EDITOR:-nano} ~/.p10k.zsh'

alias gs='git status'
alias gd='git diff'
alias gc='git commit -v'
alias gca='git commit -v --amend'
alias glog="git log --oneline --graph --decorate --all"

# ── Environment ───────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"
export PAGER="less"
export LESS="-R --use-color"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ── Useful functions ──────────────────────────────────────────────────────────

# `mkcd foo` — create dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# `bak file` — quick backup with timestamp
bak() { cp "$1" "${1}.bak.$(date +%Y%m%d_%H%M%S)"; }

# `extract` fallback (covered by OMZ plugin, but just in case)
# Already provided by the extract plugin above.

# `fcd` — interactive cd with fzf
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git . "${1:-.}" 2>/dev/null | \
        fzf --preview 'exa -1 --color=always {}' +m) && cd "$dir"
}

# `fkill` — fuzzy-find and kill a process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "${1:--15}"
}

# `ghist` — fuzzy git log + show diff
ghist() {
  git log --oneline --color=always | \
  fzf --ansi --preview 'git show --color=always {1}' | \
  awk '{print $1}'
}

# `serve` — quick HTTP server in current dir
serve() { python3 -m http.server "${1:-8000}"; }

# ── Powerlevel10k config ──────────────────────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

ZSHRC_EOF

success ".zshrc written."

# ── 7. Set zsh as default shell ───────────────────────────────────────────────
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    success "Default shell changed to zsh. Log out and back in to apply."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Oh My Zsh setup complete! Next steps:             ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  1. Log out and log back in (or run: exec zsh)           ║${NC}"
echo -e "${GREEN}║  2. Set your terminal font to: MesloLGS NF               ║${NC}"
echo -e "${GREEN}║  3. Run: p10k configure  (to style your prompt)          ║${NC}"
echo -e "${GREEN}║  4. Optional: edit ~/.zshrc to tweak plugins/aliases     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
