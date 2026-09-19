# omz-plugin-pnpm

oh-my-zsh aliases for common [pnpm](https://pnpm.io) commands.

## Installation

- [Oh My Zsh](#oh-my-zsh)
- [Lightweight installation](#lightweight-installation)
- [Zinit](#zinit)

### Oh My Zsh

1. Clone the repository:

```zsh
git clone --depth=1 https://github.com/ntnyq/omz-plugin-pnpm.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/pnpm"
```

2. Include it in your `~/.zshrc`:

```zsh
plugins=(... pnpm)
```

### Lightweight installation

To install only `pnpm.plugin.zsh`, without cloning the repository, run:

<details>
<summary>Installation commands and update behavior</summary>

```sh
(
  set -e
  installer=$(mktemp "${TMPDIR:-/tmp}/omz-plugin-pnpm.XXXXXXXX")
  trap 'rm -f -- "$installer"' 0
  trap 'exit 1' HUP INT TERM
  curl -fsSL --connect-timeout 10 --max-time 60 --output "$installer" \
    https://raw.githubusercontent.com/ntnyq/omz-plugin-pnpm/main/install.sh
  sh "$installer"
)
```

The script requires `curl` and Zsh. It installs into
`${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/pnpm`, so you can enable it with
`plugins=(... pnpm)` in `~/.zshrc`, as above. It does not edit your shell configuration.

You can also specify a directory:

```sh
(
  set -e
  installer=$(mktemp "${TMPDIR:-/tmp}/omz-plugin-pnpm.XXXXXXXX")
  trap 'rm -f -- "$installer"' 0
  trap 'exit 1' HUP INT TERM
  curl -fsSL --connect-timeout 10 --max-time 60 --output "$installer" \
    https://raw.githubusercontent.com/ntnyq/omz-plugin-pnpm/main/install.sh
  sh "$installer" "$HOME/.local/share/zsh/plugins/pnpm"
)
```

For that custom location, add this line to `~/.zshrc`:

```zsh
source "$HOME/.local/share/zsh/plugins/pnpm/pnpm.plugin.zsh"
```

Run the same installation command again to update to the latest `main` version.
The commands run the installer only after its download succeeds. Each download
has a 10-second connection timeout and a 60-second total time limit. The script
checks the download's Zsh syntax before replacing the plugin; a failed or
interrupted download leaves the existing file intact and removes temporary files.
Git installations should use `git pull`.
Only the plugin file is installed; tests, CI configuration, and Git history are omitted.

</details>

### Zinit

Add this line to your `~/.zshrc`:

```shell
zinit light ntnyq/omz-plugin-pnpm
```

For a single-file installation, use this **instead**:

```zsh
zinit snippet https://raw.githubusercontent.com/ntnyq/omz-plugin-pnpm/main/pnpm.plugin.zsh
```

Zinit caches the snippet locally. Run `zinit update --all` to update it alongside
your other plugins and snippets. See the [Zinit snippet documentation](https://github.com/zdharma-continuum/zinit#plugins-and-snippets).

### Others

PRs are always welcome!

## Global scripts directory

> This feature is copied from [omz-plugin-yarn](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/yarn)

On macOS and other Unix systems, the plugin configures `PNPM_HOME` and adds
pnpm's executable directories to `$PATH` without invoking pnpm at shell startup.

<details>
<summary>PNPM_HOME defaults and PATH behavior</summary>

A nonempty `PNPM_HOME` is preserved. Otherwise, the plugin uses pnpm's default
data directory, in this order:

1. `$XDG_DATA_HOME/pnpm`, when `XDG_DATA_HOME` is set.
2. `$HOME/Library/pnpm` on macOS.
3. `$HOME/.local/share/pnpm` on other Unix systems.

Both `$PNPM_HOME/bin` (pnpm 11/12) and `$PNPM_HOME` (pnpm 10) are added when
missing from `$PATH`. Existing PATH entries retain their order. Directories
need not exist yet, so installing pnpm or switching between these layouts
does not require reloading the plugin. The plugin does not create directories.
`PNPM_HOME` and additional bin paths must be absolute paths without `:`.
An existing readonly `PNPM_HOME` is supported. If its value is empty, environment
and PATH initialization is skipped and aliases are still loaded.
Paths containing symbolic links followed by `..` retain their filesystem
meaning. The plugin also adds the lexically normalized paths used by pnpm 10/11;
duplicate entries are skipped, and existing PATH entries keep their priority.

</details>

<details>
<summary>Custom global bin directory and disabling initialization</summary>

If pnpm uses a custom `global-bin-dir` / `globalBinDir`, configure the same
directory separately, **before loading this plugin**:

```zsh
zstyle ':omz:plugins:pnpm' global-bin-dir "$HOME/.local/bin"
```

This style adds a directory to PATH. It does not configure pnpm itself and
does not change `PNPM_HOME`. The plugin does not read pnpm configuration files
or try to infer a home directory from a global bin directory.

To disable all environment and PATH initialization, set this style before
loading the plugin:

```zsh
zstyle ':omz:plugins:pnpm' global-path no
```

</details>

<details>
<summary>Upgrading, preserving global packages, and PATH priority</summary>

If an older plugin version placed packages under an unintended `PNPM_HOME`,
set the desired data root explicitly before loading the plugin. This change
does not move existing packages or guess which historical directory to use.

Before upgrading, record these values and the names of your global packages
in a shell where the old plugin is still loaded:

```zsh
print -r -- "$PNPM_HOME"
pnpm root -g
pnpm store path
pnpm list -g --depth 0
```

To keep using those packages with the same pnpm version, add
`export PNPM_HOME="/your/recorded/old/home"` before loading the plugin, and keep
any custom global bin configuration and matching zstyle. To use a different
data root, set it explicitly and reinstall the required global packages there.
A changed `list -g` result does not mean the old packages were deleted.
Changing pnpm's major version can also change its global package layout.

If both layouts contain an executable with the same name, normal PATH order
decides which executable runs. Newly added paths prefer the `bin` subdirectory;
existing entries retain their priority. This is layout compatibility, not an
automatic global-package migration or a package-manager version switcher.
If you want the new layout to take priority, explicitly put it first after
loading the plugin with `path=("$PNPM_HOME/bin" "${path[@]}")`.

</details>

## Aliases

| Alias | Command                              | Description                                                                             |
| ----- | ------------------------------------ | --------------------------------------------------------------------------------------- |
| p     | `pnpm`                               | The pnpm command                                                                        |
| pex   | `pnpm exec`                          | Execute a shell command in scope of a project                                           |
| pdx   | `pnpm dlx`                           | Fetch a package without installing, hotload and run it's command                        |
| pa    | `pnpm add`                           | Install a package in dependencies (`package.json`)                                      |
| pad   | `pnpm add --save-dev`                | Install a package in devDependencies (`package.json`)                                   |
| prm   | `pnpm remove`                        | Remove installed packages                                                               |
| pls   | `pnpm list`                          | List installed packages                                                                 |
| pap   | `pnpm add --save-peer`               | Install a package in peerDependencies (`package.json`)                                  |
| pga   | `pnpm add --global`                  | Install packages globally on your operating system                                      |
| pgls  | `pnpm list --global`                 | List global installed packages                                                          |
| pgrm  | `pnpm remove --global`               | Remove global installed packages from your OS                                           |
| pgu   | `pnpm update --global`               | Upgrade packages installed globally to their latest version                             |
| pi    | `pnpm init`                          | Interactively creates or updates a package.json file                                    |
| pin   | `pnpm install`                       | Install dependencies defined in `package.json`                                          |
| pinf  | `pnpm install --frozen-lockfile`     | Install dependencies defined in `package.json` without touching lockfile                |
| pr    | `pnpm run`                           | Run a defined package script                                                            |
| prun  | `pnpm run`                           | Run a defined package script                                                            |
| pst   | `pnpm start`                         | Run the start script defined in `package.json`                                          |
| pln   | `pnpm run lint`                      | Run the lint script defined in `package.json`                                           |
| pdocs | `pnpm run docs`                      | Run the docs script defined in `package.json`                                           |
| pfmt  | `pnpm run format`                    | Run the format script defined in `package.json`                                         |
| pb    | `pnpm run build`                     | Run the build script defined in `package.json`                                          |
| pd    | `pnpm run dev`                       | Run the dev script defined in `package.json`                                            |
| psv   | `pnpm run serve`                     | Run the serve script defined in `package.json`                                          |
| pt    | `pnpm test`                          | Run the test script defined in `package.json`                                           |
| ptc   | `pnpm test --coverage`               | Run the test script defined in `package.json` with coverage                             |
| pu    | `pnpm update`                        | Update packages to their latest version based on the specified range                    |
| pui   | `pnpm update --interactive`          | Prompt for which outdated packages to their latest version based on the specified range |
| puil  | `pnpm update --interactive --latest` | Prompt for which outdated packages to upgrade to the latest available version           |
| pc    | `pnpm create`                        | Create a project from a create-\* start kit                                             |
| ppub  | `pnpm publish`                       | Publish a package to the registry                                                       |
| pab   | `pnpm approve-builds`                | Approve dependencies for running scripts during installation                            |
| pf    | `pnpm -r --filter`                   | Use filter in monorepo root directory                                                   |

## Testing

<details>
<summary>Test commands, coverage, and CI</summary>

Run the shell and installer regression tests with Zsh; no Node.js or pnpm
installation is needed. Installer tests use a local download stub:

```sh
zsh -f tests/global-path.zsh
zsh -f tests/install.zsh
```

Run the integration tests with Node.js 24 and an installed pnpm 10, 11, or 12 CLI:

```sh
zsh -f tests/integration.zsh "$(command -v pnpm)"
```

Each case runs in a clean `zsh -f` process with a temporary HOME, PATH, and pnpm
configuration. Integration tests install and execute a dependency-free local
package offline. pnpm 12.0.0 rejects local tarballs in its global installer, so
that version checks CLI paths and executes a probe placed in the returned bin
directory instead. The tests do not run `pnpm setup` or use your global packages.
Temporary files are removed after the tests finish.

Regression cases also cover readonly homes with `ERR_EXIT`, symbolic links
followed by `..`, links created or retargeted after startup, and command priority
when the old home is already on PATH. The pnpm 12.4.2 symlink-home case checks
CLI paths and command lookup only: its installer misresolves local tarball
references with that home path. Other supported cases test actual bin linking.

GitHub Actions runs all suites on Linux and macOS, using Node.js 24 with pnpm pinned to
10.0.0, 11.0.0, 11.26.0, 12.0.0, and 12.4.2. CI downloads its tools outside the
repository; the plugin has no additional runtime dependencies.

</details>

## CHANGELOG

<details>
<summary>Release history</summary>

### 2026-09-19

- Fix `PNPM_HOME` initialization after [#18](https://github.com/ntnyq/omz-plugin-pnpm/pull/18): preserve an existing home while repairing PATH, handle empty values, and respect XDG and platform defaults.
- Support pnpm 10 and pnpm 11/12 executable layouts without invoking pnpm at shell startup or deriving its home from a bin directory.
- Add the `global-bin-dir` zstyle for explicitly configured global executable directories.
- Add a lightweight single-file installer with safe updates and document Zinit snippet installation.
- Add isolated shell, installer, and real pnpm regression tests, plus Linux and macOS CI.

### 2025-02-15

- New aliases
  - `pab` for `pnpm approve-builds`

### 2024-05-23

- New aliases
  - `pinf` for `pnpm install --frozen-lockfile`

### 2024-04-13

- Features
  - Set `PNPM_HOME` environment variable to global bin dir

### 2024-03-13

- New aliases
  - `pui` for `pnpm update --interactive`

### 2023-08-14

- New aliases
  - `pfmt` for `pnpm run format`

### 2023-03-15

- Features
  - Add pnpm global scripts dir to `$PATH`

### 2022-12-16

- New aliases
  - `pr` for `pnpm run`

### 2022-09-24

- New aliases
  - `pf` for `pnpm -r --filter`

### 2022-07-15

- Removed aliases
  - `pun` for `pnpm uninstall`. Use `prm` instead.
  - `px` for `pnpx`. It's deprecated. Use `pex` and `pdx` instead.
  - `pui` for `pnpm update --interactive`. Use `pu` and `puil` instead.
  - `pdoc` for `pnpm run doc`. Maybe rename your scripts to `docs` and use `pdocs` instead.
  - `psv` for `pnpm server`.
  - `ph` for `pnpm help`.
  - `pout` for `pnpm outdated`.
  - `pau` for `pnpm audit`.
  - `pwhy` for `pnpm why`.
- Changed aliases
  - `pup` for `pnpm update` has been renamed to `pu`.
  - `ps` for `pnpm run serve` has been renamed to `psv`. See [issue #6](https://github.com/ntnyq/omz-plugin-pnpm/issues/6)
- New aliases
  - `pex` for `pnpm exec`.
  - `pdx` for `pnpm dlx`.

</details>
