#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Enable bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
fi

# Zoxide configuration (better cd command)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd bash)"
fi

# Better history configuration
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend
shopt -s checkwinsize

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# History configuration for better search
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# fzf configuration (install with: sudo pacman -S fzf)
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

eval "$(starship init bash)"

fastfetch
