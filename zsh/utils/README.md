# ZSH Utilities

A shell-scripting utilities module made for ZSH.
This module is definitely a major component of Scwrypts, but is also standalone and can be sourced by any ZSH script to utilize (almost) all of the features.

## Usage
Import `utils.module.zsh` to activate all of the features.
Doing so will *also* check for path dependencies and required environment variables (see [Dependencies](#dependencies) and [Environment](#environment) below).


```shell
#!/bin/zsh
source ./path/to/utils.plugin.zsh
echo.success 'ZSH utilities online!'
```

Checkout [io](./io.zsh) and [os](./os.zsh) for available simple functions.

### Dependencies
Ensures dependent programs are available for execution.
Specify a simple name to check the current `PATH`, or give a fully-qualified path for arbitrary dependency inclusion.

Include a dependency by adding to the `DEPENDENCIES` array.
*Always using `+=` makes your dependencies extensible to other scripts :)*

If any dependencies are missing, `source utils.module.zsh` will return an error code and count the number of missing dependencies in the variable `DEP_ERROR_COUNT`.

```shell
#!/bin/zsh
DEPENDENCIES+=(
	path-executable-1
	path-executable-2
	/path/to/arbitrary/program
)
source ./path/to/utils.plugin.zsh
echo "missing $DEP_echo.error required dependencies"
```

### Environment
Similar to [Dependencies](#dependencies), `environment.zsh` ensures a list of environment variables are *set to non-empty values*.

Include an environment variable by adding to the `REQUIRED_ENV` array.
*Something something use `+=` here too ;)*

If any environment variables are missing, `source utils.module.zsh` will return an error code and count the number of missing variables in `ENV_ERROR_COUNT`.

Missing environment variables will be added to the environment template (*exclusive to Scwrypts*).

```shell
#!/bin/zsh
REQUIRED_ENV+=(
	AWS_PROFILE
	AWS_REGION
)
source ./path/to/utils.plugin.zsh
echo "missing $ENV_ERROR_COUNT required environment variables"
```
