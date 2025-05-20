#!/usr/bin/env bash

# If Arg0 then we are searching, otherwise we open directly
# If Arg0 != "." then it will be used as query input

TARGET_PATH=~/Desktop/Notes/dojo
FILE_NAME="$(date +'%d-%m-%Y').md"

DAILY_NOTE_DIR="$TARGET_PATH/_daily"
NOTE_PATH="$DAILY_NOTE_DIR/$FILE_NAME"

# Ensure the directory exists (mkdir -p ignores existing dirs)
mkdir -p "$DAILY_NOTE_DIR"

if [ ! -e "$FULL_FILE_PATH" ]; then
  touch "$NOTE_PATH"
fi

echo $TARGET_PATH
ls $TARGET_PATH

session_file=$NOTE_PATH

if [[ -n "${1-}" ]]; then
  query="$1"

  if [[ "$query" == "." ]]; then
    query=""
  fi

  session_file=$(  fd --type f '' "$TARGET_PATH"| fzf --query="$query" --select-1 )
fi 

session_folder="$(dirname "$session_file")"
session_name="${session_file##*/}"
session_name="${session_name%.*}"

echo $session_folder
echo $session_file
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
    # after attaching, send nvim:
    tmux send-keys -t "$session_name" "nvim $NOTE_PATH" C-m
  else
    echo "Session '$session_name' does not exist. Creating..."
    tmux new-session -d -s "$session_name" -c "$DAILY_NOTE_DIR"
    tmux switch-client -t "=$session_name"
    # after attaching, send nvim:
    tmux send-keys -t "=$session_name" "nvim $NOTE_PATH" C-m
  fi
  exit 1
fi

# Check if the session exists
if tmux has-session -t "=$session_name" 2>/dev/null; then
  echo "Session '$session_name' exists. Attaching..."
  tmux attach -t "=$session_name"
  # after attaching, send nvim:
  tmux send-keys -t "=$session_name" "nvim $NOTE_PATH" C-m
else
  echo "Session '$session_name' does not exist. Creating..."
  tmux new -s "$session_name" -c "$DAILY_NOTE_DIR"
  # after attaching, send nvim:
  tmux send-keys -t "=$session_name" "nvim $NOTE_PATH" C-m
fi
