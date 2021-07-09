# Pnpm plugin

This plugin adds many useful aliases for common Pnpm commands.

To use it, add `pnpm` to the plugins array in your zshrc file:

```zsh
plugins=(... pnpm)
```

## Aliases

| Alias | Command                              | Description                                                                   |
| ----- | ------------------------------------ | ----------------------------------------------------------------------------- |
| p     | `pnpm`                               | The Pnpm command                                                              |
| px    | `pnpx`                               | Pnpm execute. Fetch a package, hotload it and run command                     |
| pa    | `pnpm add`                           | Install a package in dependencies (`package.json`)                            |
| pad   | `pnpm add --save-dev`                | Install a package in devDependencies (`package.json`)                         |
| pap   | `pnpm add --save-peer`               | Install a package in peerDependencies (`package.json`)                        |
| pb    | `pnpm run build`                     | Run the build script defined in `package.json`                                |
| pd    | `pnpm run dev`                       | Run the dev script defined in `package.json`                                  |
| pga   | `pnpm add --global`                  | Install packages globally on your operating system                            |
| pgls  | `pnpm list --global`                 | Lists global installed packages                                               |
| pgrm  | `pnpm remove --global`               | Remove global installed packages from your OS                                 |
| pgu   | `pnpm update --global`               | Upgrade packages installed globally to their latest version                   |
| ph    | `pnpm help`                          | Show help for a pnpm command                                                  |
| pau   | `pnpm audit`                         | Checks for known security issues with the installed packages                  |
| pwhy  | `pnpm why`                           | Shows the packages that depend on given package                               |
| pi    | `pnpm init`                          | Interactively creates or updates a package.json file                          |
| pin   | `pnpm install`                       | Install dependencies defined in `package.json`                                |
| pun   | `pnpm uninstall`                     | Uninstall dependencies defined in `package.json`                              |
| pln   | `pnpm run lint`                      | Run the lint script defined in `package.json`                                 |
| pdoc  | `pnpm run doc`                       | Run the doc script defined in `package.json`                                  |
| pls   | `pnpm list`                          | List installed packages                                                       |
| pout  | `pnpm outdated`                      | Check for outdated package dependencies                                       |
| prm   | `pnpm remove`                        | Remove installed packages                                                     |
| prun  | `pnpm run`                           | Run a defined package script                                                  |
| ps    | `pnpm run serve`                     | Start the dev server                                                          |
| pst   | `pnpm start`                         | Run the start script defined in `package.json`                                |
| pt    | `pnpm test`                          | Run the test script defined in `package.json`                                 |
| ptc   | `pnpm test --coverage`               | Run the test script defined in `package.json` with coverage                   |
| pui   | `pnpm update --interactive`          | Prompt for which outdated packages to upgrade                                 |
| puil  | `pnpm update --interactive --latest` | Prompt for which outdated packages to upgrade to the latest available version |
| pup   | `pnpm update`                        | Upgrade packages to their latest version                                      |
| psv   | `pnpm server`                        | Manage a pnpm store server                                                    |
| ppub  | `pnpm publish`                       | Publishes a package to the registry                                           |
