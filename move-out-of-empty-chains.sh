#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
root="$(cd "$root" && pwd)"

# Move regular files from $dir up to its parent
move_files_up() {
  local dir="$1"
  local parent
  parent="$(dirname "$dir")"
  
  [[ "$parent" == "$dir" ]] && return 1  # Already at root
  
  local moved_any=0
  shopt -s nullglob
  
  for f in "$dir"/*; do
    if [[ -f "$f" ]]; then
      local base target i
      base="$(basename "$f")"
      target="$parent/$base"
      
      # Avoid overwrites with numeric suffix
      if [[ -e "$target" ]]; then
        i=1
        while [[ -e "$parent/${base}.$i" ]]; do
          ((i++))
        done
        target="$parent/${base}.$i"
      fi
      
      if mv -v -- "$f" "$target"; then
        moved_any=1
      fi
    fi
  done
  
  shopt -u nullglob
  return "$moved_any"
}

# Check if dir contains files or non-empty subdirs
dir_has_content() {
  local dir="$1"
  
  # Has regular files?
  [[ -n "$(find "$dir" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]] && return 0
  
  # Has non-empty subdirs?
  while IFS= read -r sub; do
    if dir_has_content "$sub"; then
      return 0
    fi
  done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
  
  return 1  # Empty
}

# Main loop
max_iterations=1000
iteration=0

while [[ $iteration -lt $max_iterations ]]; do
  ((iteration++))
  any_moved=0
  
  # Process directories deepest first
  while IFS= read -r d; do
    [[ "$d" == "$root" ]] && continue
    
    # If dir has content, skip it
    dir_has_content "$d" && continue
    
    # Move files up
    if move_files_up "$d"; then
      any_moved=1
      # Try to remove empty dir
      rmdir -v -- "$d" 2>/dev/null || true
    fi
  done < <(find "$root" -type d -print | awk '{ print length, $0 }' | sort -rn | cut -d' ' -f2-)
  
  [[ $any_moved -eq 0 ]] && break
done

echo "Completed in $iteration iteration(s)."
