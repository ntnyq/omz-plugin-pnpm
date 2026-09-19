#!/usr/bin/env zsh
emulate -R zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

test_script="${0:A}"
source "${test_script:h}/helpers.zsh"

if [[ "${1-}" != --case ]]; then
  [[ -n "${1-}" && -x "$1" ]] || fail 'Usage: zsh -f tests/integration.zsh /path/to/pnpm [plugin]'
  TEST_PNPM_BIN="${1:A}"
  TEST_NODE_BIN="${commands[node]-}"
  [[ -n "$TEST_NODE_BIN" ]] || fail 'Node.js must be available on PATH'
  TEST_NODE_BIN="${TEST_NODE_BIN:A}"
  test_plugin="${2:-${test_script:h:h}/pnpm.plugin.zsh}"
  run_cases "$test_script" "${test_plugin:A}" \
    unset-home empty-home default-home preset-home home-ending-in-bin \
    special-characters custom-bin symlink-home symlink-custom-bin
  exit $?
fi

test_case="$2"
test_plugin="$3"
cd "$TEST_ROOT/project"
block_startup_commands
expected_home="$XDG_DATA_HOME/pnpm"

case "$test_case" in
  unset-home) ;;
  empty-home) export PNPM_HOME='' ;;
  default-home)
    unset XDG_DATA_HOME
    case "$OSTYPE" in
      darwin*) expected_home="$HOME/Library/pnpm" ;;
      *) expected_home="$HOME/.local/share/pnpm" ;;
    esac
    ;;
  preset-home|custom-bin)
    export PNPM_HOME="$TEST_ROOT/custom"
    expected_home="$PNPM_HOME"
    ;;
  home-ending-in-bin)
    export PNPM_HOME="$TEST_ROOT/custom/bin"
    expected_home="$PNPM_HOME"
    ;;
  special-characters)
    export PNPM_HOME="$TEST_ROOT/home with [brackets]"
    expected_home="$PNPM_HOME"
    ;;
  symlink-home|symlink-custom-bin)
    mkdir -p "$TEST_ROOT/alias" "$TEST_ROOT/real/child"
    ln -s "$TEST_ROOT/real/child" "$TEST_ROOT/alias/link"
    if [[ "$test_case" == symlink-home ]]; then
      export PNPM_HOME="$TEST_ROOT/alias/link/../pnpm"
      expected_home="$PNPM_HOME"
    fi
    ;;
  *) fail "Unknown case: $test_case" ;;
esac

if [[ "$test_case" == *custom-bin ]]; then
  custom_bin="$TEST_ROOT/independent [bin]"
  [[ "$test_case" != symlink-custom-bin ]] || custom_bin="$TEST_ROOT/alias/link/../commands"
  zstyle ':omz:plugins:pnpm' global-bin-dir "$custom_bin"
fi

load_plugin
assert_equal "$expected_home" "${PNPM_HOME-}" 'PNPM_HOME'
assert_absent "$PNPM_HOME"
original_path="$PATH"
load_plugin
assert_equal "$original_path" "$PATH" 'Repeated loading'
unfunction pnpm node corepack

# Expose only the selected CLI and Node, without pnpm setup or inherited PATH.
mkdir "$TEST_ROOT/tools"
ln -s "$TEST_NODE_BIN" "$TEST_ROOT/tools/node"
ln -s "$TEST_PNPM_BIN" "$TEST_ROOT/tools/pnpm"
path=("$TEST_ROOT/tools" "${path[@]}")
export npm_config_userconfig="$TEST_ROOT/user.npmrc"
export npm_config_globalconfig="$TEST_ROOT/global.npmrc"
version=$(pnpm --version)
expected_cli_home="$PNPM_HOME"
case "$version" in
  10.*)
    expected_cli_home="${PNPM_HOME:a}"
    expected_bin="$PNPM_HOME"
    ;;
  11.*)
    expected_cli_home="${PNPM_HOME:a}"
    expected_bin="$expected_cli_home/bin"
    ;;
  12.*) expected_bin="$PNPM_HOME/bin" ;;
  *) fail "Unsupported pnpm version in integration tests: $version" ;;
esac

if [[ "$test_case" == *custom-bin ]]; then
  expected_bin="$custom_bin"
  case "$version" in
    10.*) export npm_config_global_bin_dir="$custom_bin" ;;
    # pnpm 12.0.0 ignores globalBinDir in config.yaml; use its env override.
    12.0.0) export pnpm_config_global_bin_dir="$custom_bin" ;;
    *)
      mkdir -p "$XDG_CONFIG_HOME/pnpm"
      node -e 'console.log(JSON.stringify({ globalBinDir: process.argv[1] }))' "$custom_bin" \
        > "$XDG_CONFIG_HOME/pnpm/config.yaml"
      ;;
  esac
fi

# pnpm 10's write-access check also uses a lexically normalized path.
# Create both only after checking that plugin startup creates neither.
if [[ "$test_case" == symlink-* ]]; then
  mkdir -p "$expected_cli_home" "$expected_bin" "${expected_bin:a}"
fi

actual_bin=$(pnpm bin -g)
actual_root=$(pnpm root -g)
assert_equal "$expected_bin" "$actual_bin" "pnpm $version global bin"
[[ "$actual_root" == "$expected_cli_home"/* ]] || fail "Global root escaped PNPM_HOME: $actual_root"
assert_in_path "$actual_bin"

expected_install_bin="$actual_bin"
if [[ "$version" == 10.* || "$version" == 11.* ]]; then
  # These CLIs normalize bin destinations when linking global packages, even
  # when bin -g reports the original path (pnpm 10 homes and custom bins).
  expected_install_bin="${actual_bin:a}"
fi

if [[ "$version" == 12.0.0 || ( "$version" == 12.4.2 && "$test_case" == symlink-home ) ]]; then
  # pnpm 12.0.0's global installer rejects local tarballs and --offline.
  # pnpm 12.4.2 also misresolves local tarball references under symlink/...
  # Still check real CLI paths and command lookup; other cases test linking.
  mkdir -p "$actual_bin"
  print -rl -- '#!/bin/sh' 'printf "%s\n" pnpm-path-ok' > "$actual_bin/omz-pnpm-path-probe"
  chmod +x "$actual_bin/omz-pnpm-path-probe"
  print -r -- "# pnpm $version / $test_case: CLI paths and command lookup only"
else
  # Install a dependency-free local package to exercise real pnpm bin linking.
  # A closed local registry also prevents accidental external registry requests.
  mkdir "$TEST_ROOT/package"
  print -r -- '{"name":"omz-pnpm-path-probe","version":"1.0.0","bin":{"omz-pnpm-path-probe":"probe.sh"}}' \
    > "$TEST_ROOT/package/package.json"
  print -rl -- '#!/bin/sh' 'printf "%s\n" pnpm-path-ok' > "$TEST_ROOT/package/probe.sh"
  chmod +x "$TEST_ROOT/package/probe.sh"
  COPYFILE_DISABLE=1 tar -czf "$TEST_ROOT/probe.tgz" -C "$TEST_ROOT" package
  if ! pnpm add --global --offline --ignore-scripts \
    --registry=http://127.0.0.1:9 "$TEST_ROOT/probe.tgz" > "$TEST_ROOT/install.log" 2>&1; then
    cat "$TEST_ROOT/install.log" >&2
    fail "pnpm $version global installation failed"
  fi
fi
rehash
assert_equal "$expected_install_bin/omz-pnpm-path-probe" "$(whence -p omz-pnpm-path-probe)" 'Resolve installed command'
assert_equal pnpm-path-ok "$(omz-pnpm-path-probe)" 'Run installed command'
assert_equal "$expected_home" "$PNPM_HOME" 'Preserve home after installation'
for directory in bin global package-manager-store node_modules; do
  assert_absent "$PWD/$directory"
done
