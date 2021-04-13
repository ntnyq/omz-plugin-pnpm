if ! (( $+commands[pnpm] )); then
  print "zsh pnpm plugin: pnpm not found. Please install pnpm before using this plugin." >&2
  return 1
fi

# ALIASES

alias p='pnpm'

# Packages
alias pa='pnpm add'
alias pad='pnpm add --save-dev'
alias pap='pnpm add --save-peer'
alias prm='pnpm remove'
alias pin='pnpm install'
alias pun='pnpm uninstall'
alias pls='pnpm list'
alias pout='pnpm outdated'
alias pau='pnpm audit'
alias pwhy='pnpm why'
alias pui='pnpm update --interactive'
alias puil='pnpm update --interactive --latest'

# Global packages
alias pga='pnpm add --global'
alias pgls='pnpm list --global'
alias pgrm='pnpm remove --global'
alias pgu='pnpm update --global'

# Scripts
alias prun='pnpm run'
alias pd='pnpm run dev'
alias pb='pnpm run build'
alias ps='pnpm run serve'
alias pst='pnpm start'
alias pt='pnpm test'
alias ptc='pnpm test --coverage'
alias pln='pnpm run lint'
alias pdoc='pnpm run doc'

# Miscs
alias ph='pnpm help'
alias pi='pnpm init'
alias ppub='pnpm publish'
alias psv='pnpm server'
