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

Command       | Description
------------- | ---------------------------------------------------------------------------------------
`edit`        | edit an existing environment; synchronizes environments if new variables are added
`copy`        | copy an existing environment to a new one
`delete`      | permanently delete an environment by name
`synchronize` | uses [template](../../.template.env) to add missing and remove extemporaneous variables

## Logs
Quickly view or clear Scwrypts logs.

## Virtualenv
In addition to the custom environment sandbox, scwrypts will load the appropriate virtual environment for the current script.
Update / create the environment with `update-all`.
Drop and recreate the environment with `refresh`.
