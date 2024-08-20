# Meta Scwrypts

The fastest way to configure scwrypts is through scwrypts!
The ZSH scripts in this library are used to manage Scwrypts artifacts.


## Configure
**Great for first-time setup!**

It is simple to edit the local dot-config and restart your terminal.
It is much faster to hit `CTRL+W` and select `config/edit` through a fuzzy search.
This will immediately open your custom configuration file and reload any necessary resources on save.

## Environment
If you use Scwrypts, **you should use these commands all the time**.
This is your gateway to managing scwrypts sandboxed environments.

Command           | Description
----------------- | ---------------------------------------------------------------------------------------
`edit`            | edit an existing environment
`copy`            | create and edit a new environment from an existing one
`delete`          | permanently delete an environment by name
`stage-variables` | stage missing variables; [helpful for non-ZSH scwrypts](../../py/scwrypts/getenv.py)
`synchronize`     | uses [template](../../.env.template) to add missing and remove extemporaneous variables

### Environment Inheritance
You can make a child environment by naming an environment `<parent-name>.<child-name>`.
Children inherit all parent-set values, and **parent-set values overwrite child-set values**.
Remember that synchronize runs *every time you edit an environment*, so changes propagate to children immediately.
Inherited values are denoted by `# from <parent-name>` in the environment file.

Nested children will inherit values from all parents.

### Special Environment Variable Syntax

All environment variables which end in `__[a-z_]+` are ignored by the template file.
These environment variables *will propagate to children*, but will not be removed nor staged into the `.env.template`.

#### `__select` Environment Variables
Omit any variable, but provide a comma-separated list with the `__select` suffix, and the user will be prompted to select a value from the provided options.

In the following configuration, the user will be prompted to select an `AWS_REGION` once at the beginning of scwrypt execution:

```zsh
export AWS_REGION=
export AWS_REGION__select=us-east-1,us-east-2,us-west-1,us-west-2
```

Setting the `AWS_REGION` variable will cause scwrypts to ignore the `__select` syntax.

CI will fail on select, because CI fails on any utils.fzf prompt.

#### `__override` Environment Variables
Override any variable with the indicated value.
This will take precedence over existing values *and* any other special environment variable types.

Examples of use:
- temporarily changing a single value in your current session (e.g. `export VARIABLE__override=value`)
- overriding a variable for a one-time command (e.g. `VARIABLE__override=value scwrypts ...`)


## Logs
Quickly view or clear Scwrypts logs.

## Virtualenv
In addition to the custom environment sandbox, scwrypts will load the appropriate virtual environment for the current script.
Update / create the environment with `update-all`.
Drop and recreate the environment with `refresh`.
