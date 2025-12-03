#!/usr/bin/env bash
set -euo pipefail

ensure_lines() {
  local dest="$1"
  local src="$2"
  if [ ! -f "$src" ] || [ -z "$dest" ]; then
    return 0
  fi
  touch "$dest"
  printf "${Gray}Updating ${Cyan}%s ${Gray} with ${Cyan}%s${Color_Off}\n" "$src" "$dest"
  while IFS= read -r line || [ -n "$line" ]; do
    if ! grep -Fxq "$line" "$dest"; then
      printf '%s\n' "$line" >> "$dest"
    fi
  done < "$src"
}

ensure_env_vars() {
  local dest="$1"
  local src="$2"
  local force="$3"
  if [ -z "$dest" ] || [ ! -f "$src" ]; then
    return 0
  fi
  touch "$dest"
  printf "${Gray}Updating ${Cyan}%s ${Gray} with ${Cyan}%s${Color_Off}\n" "$src" "$dest"
  while IFS= read -r line || [ -n "$line" ]; do
    local expanded key existing force_flag
    expanded=$(envsubst <<< "$line")
    if [ -z "$expanded" ] || [ "${expanded#\#}" != "$expanded" ]; then
      continue
    fi
    key="${expanded%%=*}"
    if [ -z "$key" ]; then
      continue
    fi
    if grep -Fxq "$expanded" "$dest"; then
      continue
    fi
    existing=$(grep -m1 -E "^${key}=" "$dest" || true)
    force_flag=false
    if [ "$force" = "1" ] || [ "$force" = "true" ] || [ "$force" = "force" ] || [ "$force" = "override" ]; then
      force_flag=true
    fi
    if [ -n "$existing" ] && [ "$existing" != "$expanded" ]; then
      if [ "$force_flag" = "true" ]; then
        local tmp
        tmp=$(mktemp)
        awk -v key="$key" -v value="$expanded" '
          BEGIN { replaced = 0 }
          {
            if (!replaced && $0 ~ "^" key "=") {
              print value
              replaced = 1
              next
            }
            print
          }
          END {
            if (!replaced) {
              print value
            }
          }
        ' "$dest" > "$tmp"
        mv "$tmp" "$dest"
      fi
    else
      printf '%s\n' "$expanded" >> "$dest"
    fi
  done < "$src"
}

case "${1:-}" in
  ensure_lines)
    ensure_lines "$2" "$3"
    ;;
  ensure_env_vars)
    ensure_env_vars "$2" "$3" "${4:-}"
    ;;
  *)
    printf 'Usage: %s <ensure_lines|ensure_env_vars> <dest> <source> [force]\n' "$0"
    exit 1
    ;;
esac
