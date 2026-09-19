if zstyle -T ':omz:plugins:pnpm' global-path; then
  if [[ -n "$PNPM_HOME" ]]; then
    # `PNPM_HOME` is already configured (e.g. by `pnpm setup`, a container image
    # or a devcontainer feature). Trust it and skip the pnpm call, see #14.
    # Whoever set `PNPM_HOME` is responsible for putting the bin dir on $PATH.
    :
  else
    # Skip pnpm call if default global bin dir exists
    [[ -d "$HOME/Library/pnpm" ]] && bindir="$HOME/Library/pnpm" || bindir="$(pnpm -g bin 2>/dev/null)"

    # Only touch the environment when pnpm returned an existing directory.
    # Never export an empty `PNPM_HOME`: pnpm then treats the current working
    # directory as its home and litters `global/` and `package-manager-store/`
    # into whatever project you run it from.
    if [[ -n "$bindir" && -d "$bindir" ]]; then
      # pnpm >= 11 links global binaries into "$PNPM_HOME/bin", older versions
      # into "$PNPM_HOME" itself. Derive the home dir accordingly, see #14.
      if [[ "${bindir:t}" == "bin" ]]; then
        export PNPM_HOME="${bindir:h}"
      else
        export PNPM_HOME="$bindir"
      fi

      # Add pnpm bin directory to $PATH if not already in $PATH
      (( ! ${path[(Ie)$bindir]} )) && path+=("$bindir")
    fi
    unset bindir
  fi
fi

if zstyle -T ':omz:plugins:pnpm' aliases; then
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
fi

if zstyle -T ':omz:plugins:pnpm' completion; then
  source <(pnpm completion zsh)
fi
