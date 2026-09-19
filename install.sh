#!/bin/sh

install_plugin() (
  set -eu

  case "${1-}" in
    -h|--help)
      printf '%s\n' \
        'Usage: sh install.sh [directory]' \
        'Install or update only pnpm.plugin.zsh from the main branch.' \
        'Default: ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/pnpm'
      exit 0
      ;;
  esac
  if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ -z "$1" ]; }; then
    printf '%s\n' 'Usage: sh install.sh [directory]' >&2
    exit 1
  fi

  if [ "$#" -eq 1 ]; then
    install_dir=$1
  elif [ -n "${ZSH_CUSTOM-}" ]; then
    install_dir=$ZSH_CUSTOM/plugins/pnpm
  else
    install_dir=${HOME:?HOME must be set, or pass an installation directory}/.oh-my-zsh/custom/plugins/pnpm
  fi
  case "$install_dir" in
    /*) ;;
    *) install_dir=./$install_dir ;;
  esac

  for tool in curl zsh; do
    command -v "$tool" >/dev/null 2>&1 || {
      printf 'Required command not found: %s\n' "$tool" >&2
      exit 1
    }
  done
  if [ -e "$install_dir/.git" ]; then
    printf 'Git installation found at %s; update it with git pull.\n' "$install_dir" >&2
    exit 1
  fi

  plugin_file=$install_dir/pnpm.plugin.zsh
  if [ -d "$plugin_file" ] || [ -L "$plugin_file" ]; then
    printf 'Expected a regular plugin file: %s\n' "$plugin_file" >&2
    exit 1
  fi

  mkdir -p "$install_dir"
  download_file=$(mktemp "$install_dir/.pnpm.plugin.zsh.XXXXXXXX")
  trap 'rm -f -- "$download_file"' 0
  trap 'exit 1' HUP INT TERM

  curl -fsSL --connect-timeout 10 --max-time 60 --output "$download_file" \
    https://raw.githubusercontent.com/ntnyq/omz-plugin-pnpm/main/pnpm.plugin.zsh
  if [ ! -s "$download_file" ]; then
    printf '%s\n' 'The downloaded plugin is empty; installation aborted.' >&2
    exit 1
  fi
  zsh -f -n "$download_file"
  chmod 644 "$download_file"
  mv -f -- "$download_file" "$plugin_file"
  printf 'Installed %s\n' "$plugin_file"
)

install_plugin "$@"
