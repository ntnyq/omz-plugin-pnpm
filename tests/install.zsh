#!/usr/bin/env zsh
emulate -R zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

test_script="${0:A}"
source "${test_script:h}/helpers.zsh"

if [[ "${1-}" != --case ]]; then
  run_cases "$test_script" "${test_script:h:h}/install.sh" \
    default custom-root custom-directory relative-directory update \
    failed-download empty-download invalid-download timed-out-download \
    interrupted-download git-install symlink help \
    readme-sh-default readme-sh-custom readme-sh-failed-download \
    readme-sh-partial-download readme-sh-installer-failure \
    readme-zsh-default readme-zsh-custom readme-zsh-failed-download \
    readme-zsh-partial-download readme-zsh-installer-failure
  exit $?
fi

test_case="$2"
installer="$3"
cd "$TEST_ROOT/project"
mkdir "$TEST_ROOT/tools"
cp "${test_script:h:h}/pnpm.plugin.zsh" "$TEST_ROOT/payload"
export INSTALL_TEST_INSTALLER="$installer"
cat > "$TEST_ROOT/tools/curl" <<'SH'
#!/bin/sh
set -eu
printf '%s\n' "$@" > "$TEST_ROOT/curl-args"
output=/dev/stdout
connect_timeout=
max_time=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output) output=$2; shift ;;
    --connect-timeout) connect_timeout=$2; shift ;;
    --max-time) max_time=$2; shift ;;
    https://*) url=$1 ;;
  esac
  shift
done
# Record missing limits separately so expected download failures cannot hide them.
if [ "$connect_timeout" != 10 ] || [ "$max_time" != 60 ]; then
  : > "$TEST_ROOT/missing-timeout"
fi
case "$url" in
  */install.sh)
    case "${INSTALL_TEST_BOOTSTRAP-}" in
      failed) exit 22 ;;
      partial)
        printf 'touch "$TEST_ROOT/executed-partial-installer"\n' > "$output"
        exit 22
        ;;
      *) cp "$INSTALL_TEST_INSTALLER" "$output" ;;
    esac
    exit 0
    ;;
esac
case "${INSTALL_TEST_DOWNLOAD-}" in
  failed) printf 'partial download\n' > "$output"; exit 22 ;;
  timed-out) printf 'partial download\n' > "$output"; exit 28 ;;
  interrupted)
    printf 'partial download\n' > "$output"
    kill -TERM "$PPID"
    exit 143
    ;;
  empty) : > "$output" ;;
  invalid) printf 'if then\n' > "$output" ;;
  *) cp "$TEST_ROOT/payload" "$output" ;;
esac
SH
chmod +x "$TEST_ROOT/tools/curl"
path=("$TEST_ROOT/tools" "${path[@]}")

destination="$HOME/.oh-my-zsh/custom/plugins/pnpm"
installer_args=()
expect_failure=0
case "$test_case" in
  custom-root)
    export ZSH_CUSTOM="$TEST_ROOT/omz custom"
    destination="$ZSH_CUSTOM/plugins/pnpm"
    ;;
  custom-directory)
    destination="$TEST_ROOT/plugin with [brackets]"
    installer_args=("$destination")
    ;;
  relative-directory)
    destination="$PWD/-plugin with spaces"
    installer_args=('-plugin with spaces')
    ;;
  failed-download|empty-download|invalid-download|timed-out-download|interrupted-download)
    export INSTALL_TEST_DOWNLOAD="${test_case%-download}"
    expect_failure=1
    ;;
  readme-*-custom)
    destination="$HOME/.local/share/zsh/plugins/pnpm"
    ;;
  readme-*-failed-download|readme-*-partial-download)
    export INSTALL_TEST_BOOTSTRAP="${${test_case#readme-*-}%-download}"
    expect_failure=1
    ;;
  readme-*-installer-failure)
    export INSTALL_TEST_DOWNLOAD=invalid
    expect_failure=1
    ;;
  git-install|symlink) expect_failure=1 ;;
  help) installer_args=(--help) ;;
esac

if [[ "$test_case" == update ]] || (( expect_failure )); then
  mkdir -p "$destination"
  print -r -- '# previous plugin' > "$destination/pnpm.plugin.zsh"
  print -r -- 'keep this file' > "$destination/keep.txt"
fi
if [[ "$test_case" == git-install ]]; then
  mkdir "$destination/.git"
elif [[ "$test_case" == symlink ]]; then
  mv "$destination/pnpm.plugin.zsh" "$TEST_ROOT/linked-plugin"
  ln -s "$TEST_ROOT/linked-plugin" "$destination/pnpm.plugin.zsh"
fi

installer_command=(/bin/sh "$installer" "${installer_args[@]}")
if [[ "$test_case" == readme-* ]]; then
  # Execute the documented commands themselves, without inherited errexit/pipefail.
  example_number=1
  [[ "$test_case" != readme-*-custom ]] || example_number=2
  awk -v target="$example_number" '
    /^### Lightweight installation$/ { in_section = 1; next }
    in_section && /^### / { exit }
    in_section && /^```sh$/ { block++; in_code = 1; next }
    in_code && /^```$/ { in_code = 0 }
    in_code && block == target { print }
  ' "${installer:h}/README.md" > "$TEST_ROOT/readme-example"
  [[ -s "$TEST_ROOT/readme-example" ]] || fail 'Missing README installation example'
  example_shell=sh
  [[ "$test_case" != readme-zsh-* ]] || example_shell=zsh
  installer_command=("${commands[$example_shell]}" "$TEST_ROOT/readme-example")
fi

result=0
"${installer_command[@]}" > "$TEST_ROOT/install.log" 2>&1 || result=$?
if (( expect_failure )); then
  (( result != 0 )) || fail 'Installation must fail'
  assert_equal '# previous plugin' "$(<"$destination/pnpm.plugin.zsh")" 'Preserve old plugin'
  assert_equal 'keep this file' "$(<"$destination/keep.txt")" 'Preserve other files'
elif [[ "$test_case" == help ]]; then
  assert_equal 0 "$result" 'Help exit status'
  assert_absent "$destination"
else
  if (( result != 0 )); then
    cat "$TEST_ROOT/install.log" >&2
    fail 'Installation failed'
  fi
  cmp "$TEST_ROOT/payload" "$destination/pnpm.plugin.zsh" || fail 'Installed contents differ'
  assert_absent "$destination/tests"
  assert_absent "$destination/.github"
  assert_absent "$destination/.git"
  assert_equal https://raw.githubusercontent.com/ntnyq/omz-plugin-pnpm/main/pnpm.plugin.zsh \
    "$(tail -1 "$TEST_ROOT/curl-args")" 'Download only the plugin'
  if [[ "$test_case" == update ]]; then
    assert_equal 'keep this file' "$(<"$destination/keep.txt")" 'Preserve other files'
  fi
fi

case "$test_case" in
  git-install|symlink|help) assert_absent "$TEST_ROOT/curl-args" ;;
esac
assert_absent "$TEST_ROOT/missing-timeout"
assert_absent "$TEST_ROOT/executed-partial-installer"
temporary_files=("$destination"/.pnpm.plugin.zsh.*(N))
assert_equal 0 "${#temporary_files}" 'Remove temporary downloads'
temporary_installers=("$TMPDIR"/omz-plugin-pnpm.*(N))
assert_equal 0 "${#temporary_installers}" 'Remove temporary installers'
