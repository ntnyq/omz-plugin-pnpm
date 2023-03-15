# omz-plugin-pnpm

oh-my-zsh aliases for common [pnpm](https://pnpm.io) commands.

## Installation

- [Oh My Zsh](#oh-my-zsh)
- [Zinit](#zinit)

### Oh My Zsh

1. Clone the repository:

```zsh
git clone --depth=1 https://github.com/ntnyq/omz-plugin-pnpm.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/pnpm
```

2. Include it in your `~/.zshrc`:

```zsh
plugins=(... pnpm)
```

### Zinit

Add script bellow to your `~/.zshrc`

```shell
zinit light ntnyq/omz-plugin-pnpm
```

### Others

PRs are always welcome!

## Global scripts directory

> This feature is copied from [omz-plugin-yarn](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/yarn)

Adding pnpm global scripts dir (commonly ~/Library/pnpm) to the `$PATH`. 

To disable this feature, set the following style in your .zshrc:

```
zstyle ':omz:plugins:pnpm' global-path false
```

## Aliases

| Alias | Command                              | Description                                                                   |
| ----- | ------------------------------------ | ----------------------------------------------------------------------------- |
| p     | `pnpm`                               | The pnpm command                                                              |
| pex   | `pnpm exec`                          | Execute a shell command in scope of a project                                 |
| pdx   | `pnpm dlx`                           | Fetch a package without installing, hotload and run it's command              |
| pa    | `pnpm add`                           | Install a package in dependencies (`package.json`)                            |
| pad   | `pnpm add --save-dev`                | Install a package in devDependencies (`package.json`)                         |
| prm   | `pnpm remove`                        | Remove installed packages                                                     |
| pls   | `pnpm list`                          | List installed packages                                                       |
| pap   | `pnpm add --save-peer`               | Install a package in peerDependencies (`package.json`)                        |
| pga   | `pnpm add --global`                  | Install packages globally on your operating system                            |
| pgls  | `pnpm list --global`                 | List global installed packages                                                |
| pgrm  | `pnpm remove --global`               | Remove global installed packages from your OS                                 |
| pgu   | `pnpm update --global`               | Upgrade packages installed globally to their latest version                   |
| pi    | `pnpm init`                          | Interactively creates or updates a package.json file                          |
| pin   | `pnpm install`                       | Install dependencies defined in `package.json`                                |
| pr    | `pnpm run`                           | Run a defined package script                                                  |
| prun  | `pnpm run`                           | Run a defined package script                                                  |
| pst   | `pnpm start`                         | Run the start script defined in `package.json`                                |
| pln   | `pnpm run lint`                      | Run the lint script defined in `package.json`                                 |
| pdocs | `pnpm run docs`                      | Run the docs script defined in `package.json`                                 |
| pb    | `pnpm run build`                     | Run the build script defined in `package.json`                                |
| pd    | `pnpm run dev`                       | Run the dev script defined in `package.json`                                  |
| psv   | `pnpm run serve`                     | Run the serve script defined in `package.json`                                |
| pt    | `pnpm test`                          | Run the test script defined in `package.json`                                 |
| ptc   | `pnpm test --coverage`               | Run the test script defined in `package.json` with coverage                   |
| pu    | `pnpm update`                        | Update packages to their latest version based on the specified range          |
| puil  | `pnpm update --interactive --latest` | Prompt for which outdated packages to upgrade to the latest available version |
| pc    | `pnpm create`                        | Create a project from a create-\* start kit                                   |
| ppub  | `pnpm publish`                       | Publish a package to the registry                                             |
| pf    | `pnpm -r --filter`                   | Use filter in monorepo root directory                                         |

## CHANGELOG

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
