# *Scwrypts*

Scwrypts is a CLI and API for safely running scripts in the terminal, CI, and other automated environments.

Local runs provide a user-friendly approach to quickly execute CI workflows and automations in your terminal.
Each local run runs through an interactive, *sandboxed environment* so you never accidentally run dev credentials in production ever again!

## Major Version Upgrade Notice

Please refer to [Version 4 to Version 5 Upgrade Path](./docs/upgrade/v4-to-v5.md) when upgrading from scwrypts v4 to scwrypts v5!

## Installation

Quick installation is supported through both the [Arch User Repository](https://aur.archlinux.org/packages/scwrypts) and [Homebrew](https://github.com/wrynegade/homebrew-brew/tree/main/Formula)

```bash
# AUR
yay -Syu scwrypts

# homebrew
brew install wrynegade/scwrypts
```

### Manual Installation

To install scwrypts manually, clone this repository (and take note of where it is installed)
Replacing the `/path/to/cloned-repo` appropriately, add the following line to your `~/.zshrc`:
```zsh
source /path/to/cloned-repo/scwrypts.plugin.zsh
```

The next time you start your terminal, you can now execute scwrypts by using the plugin shortcut(s) (by default `CTRL + SPACE`).
Plugin shortcuts are configurable in your scwrypts configuration file found in `~/.config/scwrypts/config.zsh`, and [here is the default config](./zsh/config.user.zsh).

If you want to use the `scwrypts` program directly, you can either invoke the executable `./scwrypts` or link it in your PATH for easy access.
For example, if you have `~/.local/bin` in your PATH, you might run:
```zsh
ln -s /path/to/cloned-repo/scwrypts "${HOME}/.local/bin/scwrypts"
```

#### PATH Dependencies

Scwrypts provides a framework for workflows which often depend on a variety of other tools.
Although the lazy-loaded dependency model allows hardening in CI and extendability, the user is expected to _resolve required PATH dependencies_.

When running locally, this is typically as simple as "install the missing program," but this may require additional steps when working in automated environments.

By default, the `ci` plugin is enabled which provides the `check all dependencies` scwrypt.
You can run this to output a comprehensive list of PATH dependencies across all scwrypts groups, but, at a bare minimum, you will need the following applications in your PATH:

```bash
zsh

grep  # GNU
sed   # GNU
sort  # GNU

fzf   # https://github.com/junegunn/fzf (only required for interactive / local)
jo    # https://github.com/jpmens/jo
jq    # https://github.com/jqlang/jq
yq    # https://github.com/mikefarah/yq
```


## Usage in CI and Automated Environments

Set environment variable `CI=true` to run scwrypts in an automated environment.
There are a few notable changes to this runtime:
- **The Scwrypts sandbox environment will not load.** All variables will be read directly from the current context.
- User yes/no prompts will **always be YES**
- Other user input will default to an empty string
- Logs will not be captured in the user's local cache
- In GitHub actions, `*.scwrypts.zsh` groups are detected automatically from the `$GITHUB_WORKSPACE`; set `SCWRYPTS_GITHUB_NO_AUTOLOAD=true` to disable

## Contributing

Before contributing an issue, idea, or pull request, check out the [super-brief contributing guide](./docs/CONTRIBUTING.md)
