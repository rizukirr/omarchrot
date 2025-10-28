#!/bin/bash

KEYWORD=$1

if [[ -z "$KEYWORD" ]]; then
  echo "Usage sk [keyword]"
fi

fsearch() {
  rg --line-number --no-heading --color=always "$KEYWORD" |
    fzf --ansi --delimiter : \
      --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' \
      --bind 'enter:execute(nvim {1} +{2})'
}

fsearch
