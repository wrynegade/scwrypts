# *Scwrypts* (Wryn + Scripts)

Scwrypts is a friendly CLI / API for quickly running *sandboxed scripts* in the terminal.

In modern developer / dev-ops workflows, scripts require a complex configurations.
Without a better solution, the developer is cursed to copy lines-upon-lines of variables into terminals, create random text artifacts, or maybe even commit secure credentials into source.
Scwrypts leverages ZSH to give hot-key access to run scripts in such environments.


## Dependencies
Due to the wide variety of resources used by scripting libraries, the user is expected to manually resolve dependencies.
Dependencies are lazy-loaded, and more information can be found by command error messages or in the appropriate README.

Because Scwrypts relies on Scwrypts (see [Meta Scwrypts](./zsh/scwrypts)), `zsh` must be installed and [`junegunn/fzf`](https://github.com/junegunn/fzf) must be available on your PATH.

## Usage
Install Scwrypts by cloning this repository and sourcing `scwrypts.plugin.zsh` in your `zshrc`.
You can now run Scwrypts using the ZLE hotkey bound to `SCWRYPTS_SHORTCUT` (default `CTRL + W`).

```console
% cd <path-to-cloned-repo>
% echo "source $(pwd)/scwrypts.plugin.zsh >> $HOME/.zshrc"
```

Check out [Meta Scwrypts](./zsh/scwrypts) to quickly set up environments and adjust configuration.


### No Install / API Usage
Alternatively, the `scwrypts` API can be used directly:
```zsh
./scwrypts [--env environment-name] (...script-name-patterns...) [-- ...passthrough arguments... ]
```

Given one or more script patterns, Scwrypts will filter the commands by pattern conjunction.
If only one command is found which matches the pattern(s), it will immediately begin execution.
If multiple commands match, the user will be prompted to select from the filtered list.
Of course, if no commands match, Scwrypts will exit with an error.

Given no script patterns, Scwrypts becomes an interactive CLI, prompting the user to select a command.

After determining which script to run, if no environment has been specified, Scwrypts prompts the user to choose one.


### Using in CI/CD or Automated Workflows
Set environment variable `CI=true` (and use the no install method) to run in an automated pipeline.
There are a few notable changes to this runtime:
- **The Scwrypts sandbox environment will not load.** All variables will be read from context.
- User yes/no prompts will **always be YES**
- Other user input will default to an empty string
- Logs will not be captured


## Contributing

Before contributing an issue, idea, or pull request, check out the [super-brief contributing guide](./docs/CONTRIBUTING.md)
