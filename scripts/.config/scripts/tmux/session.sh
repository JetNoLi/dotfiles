#!/bin/bash
 
 #TODO:Enhancement - if the repo has a tmux_session.sh in it, will use that
 # session_folder=$(echo "$HOME/dotfiles" ; fd --type d --prune -g -H '.git' ~/Desktop -X dirname | sort -u | fzf)
 
additional_dirs=(
  "$HOME/dotfiles"
  "$HOME/Desktop/Notes"
)
 session_folder=$( (printf "%s\n" "${additional_dirs[@]}"; fd --type d --prune -g -H '.git' ~/Desktop -X dirname) | fzf --query="$1" --select-1)
 session_name="${session_folder##*/}"

echo $session_folder
echo $session_name

#   Attach tmux a $session_name
if [[ -z "$session_name" ]]; then
  echo "var1 is empty or unset"
  exit 1
fi

if [ -n "$TMUX" ]; then
  if tmux has-session -t "=$session_name" 2>/dev/null; then
    echo "Session '$session_name' exists. Attaching..."
    tmux switch-client -t "=$session_name"
  else
    echo "Session '$session_name' does not exist. Creating..."
    tmux new-session -d -s "$session_name" -c "$session_folder"
    tmux switch-client -t "=$session_name"
  fi
  exit 1
fi

# Check if the session exists
if tmux has-session -t "=$session_name" 2>/dev/null; then
  echo "Session '$session_name' exists. Attaching..."
  tmux attach -t "=$session_name"
else
  echo "Session '$session_name' does not exist. Creating..."
  tmux new -s "$session_name" -c "$session_folder"
fi
