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

# seed each env var definition from $2 into $1, but only where the key is not
# present yet — an existing value is never touched.
#
# This is the counterpart to `ensure_env_vars`, which always restores the value
# from the template. Templates mix two kinds of entry: infrastructure constants
# the bundle owns (XO_MODULES_DIR, APP_RUNTIME_ENV) and values that belong to the
# project (XO_PROJECT_NAME, POSTGRES_DB, secrets). Forcing the second kind resets
# a working setup to the bundle defaults on every `make install`, so those belong
# in a `config/.env.seed` and go through here instead.
seed_env_vars() {
  local dest="$1"
  local src="$2"
  if [ -z "$dest" ] || [ ! -f "$src" ]; then
    return 0
  fi
  printf "${Gray}Seeding ${Cyan}%s ${Gray} from ${Cyan}%s${Gray} (existing values kept)${Color_Off}\n" "$dest" "$src"
  ensure_env_vars "$dest" "$src" ""
}

remove_env_vars() {
  local dest="$1"
  local src="$2"
  if [ -z "$dest" ] || [ ! -f "$dest" ] || [ ! -f "$src" ]; then
    echo "NO FILE"
    return 0
  fi

  printf "${Gray}Removing env vars from ${Cyan}%s ${Gray} using ${Cyan}%s${Color_Off}\n" "$dest" "$src"

  local key line pattern=""
  while IFS= read -r line || [ -n "$line" ]; do
    key="${line%%=*}"
    if [ -z "$key" ]; then
      continue
    fi
    if [ -n "$pattern" ]; then
      pattern="${pattern}|"
    fi
    pattern="${pattern}${key}"
  done < "$src"

  local tmp
  tmp=$(mktemp)
  if [ -n "$pattern" ]; then
    grep -v -E "^(${pattern})=" "$dest" > "$tmp"
  else
    cp "$dest" "$tmp"
  fi
  mv "$tmp" "$dest"
}

# ensure each configured sub-repo exists and its origin points to the given remote
# $1: path to a config file with one "<folder>=<git-remote>" entry per line
#     (blank lines and lines starting with '#' are ignored)
# $2: optional branch to clone (defaults to the remote's default branch)
#
# A missing folder is cloned, an existing one only gets its origin corrected —
# the working tree and the checked-out branch are never touched, so this is safe
# to re-run. Projects without a config file are skipped, not failed.
ensure_repos() {
  local file="$1"
  local branch="${2:-}"
  local line name remote current
  if [ -z "$file" ] || [ ! -f "$file" ]; then
    printf "${Gray}No sub-repo config at ${Cyan}%s${Gray} — skipping. See ${Cyan}docker/core/config/subrepos.conf.example${Color_Off}\n" "$file"
    return 0
  fi
  printf "${Gray}Reading sub-repos from ${Cyan}%s${Color_Off}\n" "$file"
  while IFS= read -r line || [ -n "$line" ]; do
    # strip surrounding whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    # skip blanks and comments
    if [ -z "$line" ] || [ "${line#\#}" != "$line" ]; then
      continue
    fi
    name="${line%%=*}"
    remote="${line#*=}"
    if [ -z "$name" ] || [ -z "$remote" ] || [ "$name" = "$line" ]; then
      printf "${Red}Skipping invalid sub-repo entry '%s' (expected <folder>=<remote>)${Color_Off}\n" "$line"
      continue
    fi
    if [ ! -e "$name/.git" ]; then
      printf "${Gray}Cloning ${Cyan}%s${Gray} into ${Cyan}%s${Color_Off}\n" "$remote" "$name"
      if [ -n "$branch" ]; then
        git clone --branch "$branch" "$remote" "$name"
      else
        git clone "$remote" "$name"
      fi
      continue
    fi
    current=$(git -C "$name" remote get-url origin 2>/dev/null || true)
    if [ "$current" = "$remote" ]; then
      printf "${Gray}Sub-repo ${Cyan}%s${Gray} already references ${Green}%s${Color_Off}\n" "$name" "$remote"
    elif [ -n "$current" ]; then
      printf "${Gray}Updating origin of ${Cyan}%s${Gray}: ${Yellow}%s${Gray} -> ${Green}%s${Color_Off}\n" "$name" "$current" "$remote"
      git -C "$name" remote set-url origin "$remote"
    else
      printf "${Gray}Adding origin ${Green}%s${Gray} to ${Cyan}%s${Color_Off}\n" "$remote" "$name"
      git -C "$name" remote add origin "$remote"
    fi
  done < "$file"
}

case "${1:-}" in
  ensure_lines)
    ensure_lines "$2" "$3"
    ;;
  ensure_env_vars)
    ensure_env_vars "$2" "$3" "${4:-}"
    ;;
  seed_env_vars)
    seed_env_vars "$2" "$3"
    ;;
  remove_env_vars)
    remove_env_vars "$2" "$3"
    ;;
  ensure_repos)
    ensure_repos "$2" "${3:-}"
    ;;
  *)
    printf 'Usage: %s <ensure_lines|ensure_env_vars|seed_env_vars|remove_env_vars|ensure_repos> <dest> <source> [force]\n' "$0"
    exit 1
    ;;
esac
