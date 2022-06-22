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
Inherited values are denoted by `# inherited from <parent-name>` in the environment file.

Nested children will inherit values from all parents.

## Logs
Quickly view or clear Scwrypts logs.

## Virtualenv
In addition to the custom environment sandbox, scwrypts will load the appropriate virtual environment for the current script.
Update / create the environment with `update-all`.
Drop and recreate the environment with `refresh`.
