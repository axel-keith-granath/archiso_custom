# /root/.zshrc: A simple, robust Zsh config for the live environment.
#

# --- History Settings ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history inc_append_history

# --- Prompt ---
# A clean, informative prompt: [user@hostname] /current/path >
PROMPT="[%n@%m] %~ > "

# --- Keybindings & Options ---
# Use emacs-style keybindings
bindkey -e
# Enable autocompletion
autoload -U compinit && compinit

# --- Aliases ---
alias ls="ls --color=auto"
alias ll="ls -alFh"
alias la="ls -A"
alias grep="grep --color=auto"
alias ..="cd .."
alias reb="systemctl reboot"
alias shut="systemctl poweroff"