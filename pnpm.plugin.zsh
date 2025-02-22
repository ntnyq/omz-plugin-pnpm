if zstyle -T ':omz:plugins:pnpm' global-path; then
  # Skip pnpm call if default global bin dir exists
  [[ -d "$HOME/Library/pnpm" ]] && bindir="$HOME/Library/pnpm" || bindir="$(pnpm -g bin 2>/dev/null)"

  # Set `PNPM_HOME` environment variable to global bin dir, see #14
  export PNPM_HOME="$bindir"

  # Add pnpm bin directory to $PATH if it exists and not already in $PATH
  [[ $? -eq 0 ]] \
    && [[ -d "$bindir" ]] \
    && (( ! ${path[(Ie)$bindir]} )) \
    && path+=("$bindir")
  unset bindir
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
