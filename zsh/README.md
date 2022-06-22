# ZSH Scwrypts
[![Generic Badge](https://img.shields.io/badge/1password-op-informational.svg)](https://1password.com/downloads/command-line)
[![Generic Badge](https://img.shields.io/badge/BurntSushi-rg-informational.svg)](https://github.com/BurntSushi/ripgrep)
[![Generic Badge](https://img.shields.io/badge/junegunn-fzf-informational.svg)](https://github.com/junegunn/fzf)
[![Generic Badge](https://img.shields.io/badge/mikefarah-yq-informational.svg)](https://github.com/mikefarah/yq)
[![Generic Badge](https://img.shields.io/badge/stedolan-jq-informational.svg)](https://github.com/stedolan/jq)
[![Generic Badge](https://img.shields.io/badge/dbcli-pgcli-informational.svg)](https://github.com/dbcli/pgcli)
<br>

Since they emulate direct user interaction, shell scripts are often the straightforward choice for task automation.

## Basic Utilities

One of my biggest pet-peeves with scripting is when every line of a *(insert-language-here)* program is escaped to shell.
This kind of program, which doesn't use language features, should be a shell script.
While there are definitely unavoidable limitations to shell scripting, we can minimize a variety of problems with a modern shell and shared utilities library.

Loaded by `common.zsh`, the [`utils/` library](./utils) provides:
- common function wrappers to unify flags and context
- lazy dependency and environment variable validation
- consistent (and pretty) user input / output
