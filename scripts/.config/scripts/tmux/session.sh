#!/bin/bash
 
 #TODO:Enhancement - if the repo has a tmux_session.sh in it, will use that

 session_folder=$(fd --type d --prune -g -H '.git' ~/Desktop -X dirname | fzf)
 session_name="${session_folder##*/}"
# open a fuzzy finder of all project files with git directory
# use directory as session_name


echo $session_folder
echo $session_name

if [ -n "$TMUX" ]; then
  echo "Already inside a tmux session. Exiting."
  exit 1
fi

if [[ -z "$session_name" ]]; then
  echo "var1 is empty or unset"
  exit 1
fi

# Check if active session exists
#   Attach tmux a $session_name
if [[ -z "$session_name" ]]; then
  echo "var1 is empty or unset"
  exit 1
fi

# Check if the session exists
if tmux has-session -t "$session_name" 2>/dev/null; then
  echo "Session '$session_name' exists. Attaching..."
  tmux attach -t "$session_name"
else
  echo "Session '$session_name' does not exist. Creating..."
  tmux new -s "$session_name"
fi
