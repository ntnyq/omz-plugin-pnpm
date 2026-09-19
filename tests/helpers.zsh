# Shared assertions and an isolated zsh -f process for every test case.
fail() {
  print -u2 -r -- "$*"
  exit 1
}

assert_equal() {
  [[ "$1" == "$2" ]] || fail "$3: expected ${(qqq)1}, got ${(qqq)2}"
}

assert_absent() {
  [[ ! -e "$1" ]] || fail "Unexpected file or directory: $1"
}

assert_in_path() {
  local expected="$1"
  (( ${path[(Ie)$expected]} )) || fail "Missing PATH entry: $expected"
}

load_plugin() {
  local result=0
  source "$test_plugin" > "$TEST_ROOT/startup.stdout" 2> "$TEST_ROOT/startup.stderr" || result=$?
  [[ ! -s "$TEST_ROOT/startup.stdout" && ! -s "$TEST_ROOT/startup.stderr" ]] || {
    /bin/cat "$TEST_ROOT/startup.stdout" "$TEST_ROOT/startup.stderr" >&2
    fail 'Plugin startup must be silent'
  }
  assert_equal 0 "$result" 'Plugin exit status'
  assert_absent "$TEST_ROOT/startup-command"
}

block_startup_commands() {
  pnpm() {
    print -r -- "pnpm $*" >> "$TEST_ROOT/startup-command"
    return 97
  }
  node() {
    print -r -- "node $*" >> "$TEST_ROOT/startup-command"
    return 97
  }
  corepack() {
    print -r -- "corepack $*" >> "$TEST_ROOT/startup-command"
    return 97
  }
}

run_cases() {
  local test_script="$1" test_plugin="$2"
  shift 2
  local test_root case_name case_root
  local -i passed=0 failed=0
  test_root=$(mktemp -d "${TMPDIR:-/tmp}/omz-plugin-pnpm.XXXXXXXX") || return 1
  test_root="${test_root:A}"

  {
    for case_name in "$@"; do
      case_root="$test_root/$case_name"
      mkdir -p "$case_root/home" "$case_root/project"
      if /usr/bin/env -i \
        HOME="$case_root/home" \
        ZDOTDIR="$case_root/home" \
        XDG_DATA_HOME="$case_root/data" \
        XDG_CONFIG_HOME="$case_root/config" \
        XDG_CACHE_HOME="$case_root/cache" \
        XDG_STATE_HOME="$case_root/state" \
        PATH=/usr/bin:/bin \
        TMPDIR="$case_root" \
        TEST_ROOT="$case_root" \
        TEST_PNPM_BIN="${TEST_PNPM_BIN-}" \
        TEST_NODE_BIN="${TEST_NODE_BIN-}" \
        CI=true NO_COLOR=1 \
        "${commands[zsh]}" -f "$test_script" --case "$case_name" "$test_plugin"; then
        print -r -- "ok - $case_name"
        (( ++passed ))
      else
        print -u2 -r -- "not ok - $case_name"
        (( ++failed ))
      fi
    done
  } always {
    rm -rf -- "$test_root"
  }

  print -r -- "$passed passed, $failed failed"
  (( failed == 0 ))
}
