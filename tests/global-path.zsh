#!/usr/bin/env zsh
emulate -R zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

test_script="${0:A}"
source "${test_script:h}/helpers.zsh"

if [[ "${1-}" != --case ]]; then
  test_plugin="${1:-${test_script:h:h}/pnpm.plugin.zsh}"
  run_cases "$test_script" "${test_plugin:A}" \
    preset-home empty-home unset-home default-home empty-xdg xdg-priority \
    readonly-home readonly-unexported-home readonly-empty-home \
    home-ending-in-bin special-characters trailing-slash root-home \
    symlink-home symlink-late-home symlink-custom-bin existing-home-priority \
    late-install missing-pnpm disabled-unset disabled-empty disabled-preset \
    idempotent preserve-order exact-path-match custom-bin custom-bin-existing \
    invalid-custom-bin relative-home colon-home relative-xdg colon-xdg \
    missing-user-home empty-user-home scope shell-options
  exit $?
fi

test_case="$2"
test_plugin="$3"
cd "$TEST_ROOT/project"
block_startup_commands
expected_home="$XDG_DATA_HOME/pnpm"
expected_path=''
skip_home_check=0

case "$test_case" in
  preset-home|idempotent|late-install|scope|shell-options)
    export PNPM_HOME="$TEST_ROOT/custom"
    expected_home="$PNPM_HOME"
    ;;
  empty-home)
    export PNPM_HOME=''
    ;;
  readonly-home|readonly-unexported-home)
    typeset -r PNPM_HOME="$TEST_ROOT/readonly home/"
    [[ "$test_case" != readonly-home ]] || export PNPM_HOME
    expected_home="$PNPM_HOME"
    ;;
  readonly-empty-home)
    typeset -rx PNPM_HOME=''
    expected_path="$PATH"
    skip_home_check=1
    ;;
  unset-home) ;;
  default-home|empty-xdg)
    unset XDG_DATA_HOME
    [[ "$test_case" != empty-xdg ]] || export XDG_DATA_HOME=''
    case "$OSTYPE" in
      darwin*) expected_home="$HOME/Library/pnpm" ;;
      *) expected_home="$HOME/.local/share/pnpm" ;;
    esac
    ;;
  xdg-priority)
    mkdir -p "$HOME/Library/pnpm" "$HOME/.local/share/pnpm"
    export XDG_DATA_HOME="$TEST_ROOT/data with [brackets]/"
    expected_home="${XDG_DATA_HOME%/}/pnpm"
    ;;
  home-ending-in-bin)
    export PNPM_HOME="$TEST_ROOT/custom/bin"
    expected_home="$PNPM_HOME"
    ;;
  special-characters|exact-path-match)
    export PNPM_HOME="$TEST_ROOT/home with [brackets] * ?"
    expected_home="$PNPM_HOME"
    ;;
  trailing-slash)
    export PNPM_HOME="$TEST_ROOT/custom/"
    expected_home="$PNPM_HOME"
    ;;
  symlink-home|symlink-late-home|symlink-custom-bin)
    mkdir -p "$TEST_ROOT/alias" "$TEST_ROOT/real/child"
    if [[ "$test_case" != symlink-late-home ]]; then
      ln -s "$TEST_ROOT/real/child" "$TEST_ROOT/alias/link"
    fi
    if [[ "$test_case" == symlink-custom-bin ]]; then
      custom_bin="$TEST_ROOT/alias/link/../commands"
      zstyle ':omz:plugins:pnpm' global-bin-dir "$custom_bin"
    else
      export PNPM_HOME="$TEST_ROOT/alias/link/../pnpm"
      expected_home="$PNPM_HOME"
    fi
    ;;
  existing-home-priority)
    export PNPM_HOME="$TEST_ROOT/custom"
    expected_home="$PNPM_HOME"
    path=("$PNPM_HOME" /usr/bin /bin)
    ;;
  root-home)
    export PNPM_HOME=/
    expected_home=/
    ;;
  missing-pnpm)
    unfunction pnpm node corepack
    path=()
    (( ! $+commands[pnpm] )) || fail 'pnpm must be unavailable'
    ;;
  disabled-*)
    zstyle ':omz:plugins:pnpm' global-path no
    zstyle ':omz:plugins:pnpm' global-bin-dir "$TEST_ROOT/ignored"
    case "$test_case" in
      disabled-empty) export PNPM_HOME='' ;;
      disabled-preset) export PNPM_HOME="$TEST_ROOT/custom" ;;
    esac
    expected_path="$PATH"
    skip_home_check=1
    ;;
  preserve-order)
    export PNPM_HOME="$TEST_ROOT/custom"
    expected_home="$PNPM_HOME"
    path=("$PNPM_HOME" /usr/bin "$PNPM_HOME/bin" /bin)
    expected_path="$PATH"
    ;;
  custom-bin|custom-bin-existing|invalid-custom-bin)
    export PNPM_HOME="$TEST_ROOT/custom"
    expected_home="$PNPM_HOME"
    custom_bin="$TEST_ROOT/independent [bin]"
    [[ "$test_case" != invalid-custom-bin ]] || custom_bin=relative/bin
    zstyle ':omz:plugins:pnpm' global-bin-dir "$custom_bin"
    if [[ "$test_case" == custom-bin-existing ]]; then
      path=("$custom_bin" /usr/bin /bin)
    fi
    ;;
  relative-home|colon-home)
    export PNPM_HOME=relative/home
    [[ "$test_case" != colon-home ]] || export PNPM_HOME="$TEST_ROOT/bad:path"
    expected_path="$PATH"
    skip_home_check=1
    ;;
  relative-xdg|colon-xdg|missing-user-home|empty-user-home)
    export PNPM_HOME=''
    case "$test_case" in
      relative-xdg) export XDG_DATA_HOME=relative ;;
      colon-xdg) export XDG_DATA_HOME="$TEST_ROOT/bad:path" ;;
      missing-user-home) unset HOME XDG_DATA_HOME ;;
      empty-user-home) export HOME=''; unset XDG_DATA_HOME ;;
    esac
    expected_path="$PATH"
    skip_home_check=1
    ;;
  *) fail "Unknown case: $test_case" ;;
esac

if [[ "$test_case" == exact-path-match ]]; then
  # Similar strings must not be treated as an existing literal PATH entry.
  path=("$PNPM_HOME-extra" /usr/bin /bin)
fi
if [[ "$test_case" == scope ]]; then
  bindir=caller-bindir
  pnpm_home=caller-home
  pnpm_path_home=caller-path-home
  pnpm_bin=caller-bin
  pnpm_bin_dirs=(caller-dirs)
fi
if [[ "$test_case" == shell-options ]]; then
  setopt KSH_ARRAYS SH_WORD_SPLIT
fi

before_path="$PATH"
before_home="${PNPM_HOME-}"
load_plugin

if [[ "$test_case" == shell-options ]]; then
  [[ -o KSH_ARRAYS && -o SH_WORD_SPLIT && -o NO_UNSET ]] || fail 'Caller options changed'
  unsetopt KSH_ARRAYS SH_WORD_SPLIT
fi

if (( ! skip_home_check )); then
  assert_equal "$expected_home" "${PNPM_HOME-}" 'PNPM_HOME'
  [[ "${(t)PNPM_HOME}" == *export* ]] || fail 'PNPM_HOME must be exported'
  normalized_home="${expected_home:a}"
  assert_in_path "$normalized_home"
  assert_in_path "${normalized_home%/}/bin"
  [[ "$test_case" == root-home ]] || assert_absent "$PNPM_HOME"
else
  case "$test_case" in
    disabled-unset|relative-xdg|colon-xdg|missing-user-home|empty-user-home)
      assert_equal 0 "${+PNPM_HOME}" 'PNPM_HOME must remain unset' ;;
    *) assert_equal "$before_home" "${PNPM_HOME-}" 'Preserve PNPM_HOME' ;;
  esac
fi

[[ -z "$expected_path" ]] || assert_equal "$expected_path" "$PATH" 'Preserve PATH order'
case "$test_case" in
  custom-bin)
    assert_equal "$before_path:$custom_bin:$PNPM_HOME/bin:$PNPM_HOME" "$PATH" 'Custom bin priority' ;;
  custom-bin-existing)
    assert_equal "$before_path:$PNPM_HOME/bin:$PNPM_HOME" "$PATH" 'Existing custom bin priority' ;;
  invalid-custom-bin)
    assert_equal "$before_path:$PNPM_HOME/bin:$PNPM_HOME" "$PATH" 'Reject relative custom bin'
    zstyle ':omz:plugins:pnpm' global-bin-dir "$TEST_ROOT/bad:path"
    expected_path="$PATH"
    load_plugin
    assert_equal "$expected_path" "$PATH" 'Reject custom bin with colon'
    ;;
  preset-home|special-characters|exact-path-match|home-ending-in-bin)
    assert_equal "$before_path:$PNPM_HOME/bin:$PNPM_HOME" "$PATH" 'Append both layouts' ;;
  late-install)
    # New installs in either layout must work without loading the plugin again.
    mkdir -p "$PNPM_HOME/bin"
    for layout in "$PNPM_HOME" "$PNPM_HOME/bin"; do
      print -rl -- '#!/bin/sh' 'printf "%s\n" late-install-ok' > "$layout/omz-pnpm-probe"
      chmod +x "$layout/omz-pnpm-probe"
      assert_equal late-install-ok "$(omz-pnpm-probe)" 'Find newly installed command'
      rm "$layout/omz-pnpm-probe"
      rehash
    done
    ;;
esac

case "$test_case" in
  symlink-home|symlink-late-home|symlink-custom-bin)
    [[ "$test_case" != symlink-late-home ]] || ln -s "$TEST_ROOT/real/child" "$TEST_ROOT/alias/link"
    if [[ "$test_case" == symlink-custom-bin ]]; then
      probe_dirs=("$custom_bin" "${custom_bin:a}")
    else
      # pnpm 10/12 retain the path; pnpm 11 uses its lexical normalization.
      probe_dirs=("$PNPM_HOME" "$PNPM_HOME/bin" "$normalized_home/bin")
    fi
    for probe_dir in "${probe_dirs[@]}"; do
      mkdir -p "$probe_dir"
      print -rl -- '#!/bin/sh' 'printf "%s\n" symlink-ok' > "$probe_dir/omz-pnpm-probe"
      chmod +x "$probe_dir/omz-pnpm-probe"
      rehash
      assert_equal symlink-ok "$(omz-pnpm-probe)" 'Find command through symlink and ..'
      rm "$probe_dir/omz-pnpm-probe"
    done
    # A later version-manager switch must still follow the original link.
    mkdir -p "$TEST_ROOT/next/child" "$TEST_ROOT/next/pnpm/bin" "$TEST_ROOT/next/commands"
    rm "$TEST_ROOT/alias/link"
    ln -s "$TEST_ROOT/next/child" "$TEST_ROOT/alias/link"
    probe_dir="${probe_dirs[1]}"
    print -rl -- '#!/bin/sh' 'printf "%s\n" switched-ok' > "$probe_dir/omz-pnpm-probe"
    chmod +x "$probe_dir/omz-pnpm-probe"
    rehash
    assert_equal switched-ok "$(omz-pnpm-probe)" 'Follow changed symlink target'
    ;;
  existing-home-priority)
    mkdir -p "$PNPM_HOME/bin"
    print -rl -- '#!/bin/sh' 'printf "%s\n" existing-home' > "$PNPM_HOME/omz-pnpm-probe"
    print -rl -- '#!/bin/sh' 'printf "%s\n" new-bin' > "$PNPM_HOME/bin/omz-pnpm-probe"
    chmod +x "$PNPM_HOME/omz-pnpm-probe" "$PNPM_HOME/bin/omz-pnpm-probe"
    rehash
    assert_equal existing-home "$(omz-pnpm-probe)" 'Keep existing command priority'
    ;;
esac

expected_path="$PATH"
load_plugin
assert_equal "$expected_path" "$PATH" 'Repeated loading must be idempotent'
assert_equal pnpm "$aliases[p]" 'pnpm alias'
assert_equal 'pnpm -r --filter' "$aliases[pf]" 'Filter alias'
if [[ "$test_case" == readonly-* ]]; then
  [[ "${(t)PNPM_HOME}" == *readonly* ]] || fail 'Preserve readonly attribute'
  # Run source outside an OR-list so ERR_EXIT is genuinely active.
  assert_equal survived "$("${commands[zsh]}" -fec '
    typeset -r PNPM_HOME
    source "$1"
    [[ "$aliases[p]" == pnpm ]]
    print -r -- survived
  ' probe "$test_plugin")" 'Readonly home with ERR_EXIT'
fi
if [[ "$test_case" == scope ]]; then
  assert_equal caller-bindir "$bindir" 'Caller bindir'
  assert_equal caller-home "$pnpm_home" 'Caller pnpm_home'
  assert_equal caller-path-home "$pnpm_path_home" 'Caller pnpm_path_home'
  assert_equal caller-bin "$pnpm_bin" 'Caller pnpm_bin'
  assert_equal caller-dirs "$pnpm_bin_dirs[1]" 'Caller pnpm_bin_dirs'
else
  for parameter_name in bindir pnpm_home pnpm_path_home pnpm_bin pnpm_bin_dirs; do
    (( ! ${+parameters[$parameter_name]} )) || fail "Leaked parameter: $parameter_name"
  done
fi
for directory in bin global package-manager-store; do
  assert_absent "$PWD/$directory"
done
