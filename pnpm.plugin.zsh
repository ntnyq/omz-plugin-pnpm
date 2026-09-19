if zstyle -T ':omz:plugins:pnpm' global-path; then
  () {
    emulate -L zsh

    local pnpm_home="${PNPM_HOME-}"
    local pnpm_path_home pnpm_bin
    local -a pnpm_bin_dirs

    if [[ -z "$pnpm_home" ]]; then
      # An empty readonly value cannot be repaired; still load the aliases.
      [[ "${(t)PNPM_HOME}" != *readonly* ]] || return 0

      # An inherited empty value is not a valid pnpm home either.
      unset PNPM_HOME

      # Match pnpm's data-directory defaults on macOS and other Unix systems.
      if [[ -n "${XDG_DATA_HOME-}" ]]; then
        pnpm_home="${XDG_DATA_HOME%/}/pnpm"
      elif [[ -n "${HOME-}" ]]; then
        case "$OSTYPE" in
          darwin*) pnpm_home="$HOME/Library/pnpm" ;;
          *) pnpm_home="$HOME/.local/share/pnpm" ;;
        esac
      else
        return 0
      fi
    fi

    # Never add a relative path or a PATH separator to the command search path.
    [[ "$pnpm_home" == /* && "$pnpm_home" != *:* ]] || return 0

    # Keep an existing nonempty value, including a home whose name is "bin".
    [[ -n "${PNPM_HOME-}" ]] || PNPM_HOME="$pnpm_home"
    export PNPM_HOME
    pnpm_path_home="${pnpm_home%/}"
    pnpm_path_home="${pnpm_path_home:-/}"

    # pnpm 11/12 use the bin subdirectory; pnpm 10 uses the home itself.
    # Include both even before they exist, so later installs/upgrades work.
    pnpm_bin_dirs=("${pnpm_path_home%/}/bin" "$pnpm_path_home")

    # Keep symlink/.. paths intact for pnpm 10/12 and changing symlink targets.
    # pnpm 10/11 also normalize paths when installing global packages.
    pnpm_path_home="${pnpm_home:a}"
    pnpm_bin_dirs+=("${pnpm_path_home%/}/bin" "$pnpm_path_home")

    # An independently configured globalBinDir is a bin directory, not a home.
    if zstyle -s ':omz:plugins:pnpm' global-bin-dir pnpm_bin \
      && [[ "$pnpm_bin" == /* && "$pnpm_bin" != *:* ]]; then
      pnpm_bin="${pnpm_bin%/}"
      pnpm_bin="${pnpm_bin:-/}"
      pnpm_bin_dirs=("$pnpm_bin" "${pnpm_bin:a}" "${pnpm_bin_dirs[@]}")
    fi

    for pnpm_bin in "${pnpm_bin_dirs[@]}"; do
      (( ${path[(Ie)$pnpm_bin]} )) || path+=("$pnpm_bin")
    done
  }
fi

# Aliases

alias p='pnpm'

# Dependencies
alias pa='pnpm add'
alias pad='pnpm add --save-dev'
alias pap='pnpm add --save-peer'
alias prm='pnpm remove'
alias pin='pnpm install'
alias pinf='pnpm install --frozen-lockfile'
alias pls='pnpm list'
alias pu='pnpm update'
alias pui='pnpm update --interactive'
alias puil='pnpm update --interactive --latest'

# Global dependencies
alias pga='pnpm add --global'
alias pgls='pnpm list --global'
alias pgrm='pnpm remove --global'
alias pgu='pnpm update --global'

# Run scripts
alias pr='pnpm run'
alias prun='pnpm run'
alias pd='pnpm run dev'
alias pb='pnpm run build'
alias psv='pnpm run serve'
alias pst='pnpm start'
alias pt='pnpm test'
alias ptc='pnpm test --coverage'
alias pln='pnpm run lint'
alias pdocs='pnpm run docs'
alias pfmt='pnpm run format'
alias pex='pnpm exec'
alias pdx='pnpm dlx'

# Misc
alias pi='pnpm init'
alias ppub='pnpm publish'
alias pc='pnpm create'
alias pab='pnpm approve-builds'

# Monorepo
alias pf='pnpm -r --filter'
