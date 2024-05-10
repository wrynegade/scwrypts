# Scwrypts Upgrade v4 to v5 Notes

Although scwrypts v4 brings a number of new features, most functionality is backwards-compatible.

## Lots of renames!

Nearly every module received a rename.
This was a decision made to improve both style-consistency and import transparency, but has resulted in a substantial number of breaking changes to `zsh-type scwrypts modules`.

### `zsh/utils` Functions

The functions in the underlying library have all been renamed, but otherwise maintain the same functionality.
For a full reference, check out the [zsh/utils](../../zsh/utils/utils.module.zsh), but some critical renames are:
```bash
FZF            >> utils.fzf
FZF_USER_INPUT >> utils.fzf.user-input
LESS           >> utils.less
YQ             >> utils.yq

SUCCESS  >> echo.success
ERROR    >> echo.error
REMINDER >> echo.reminder
STATUS   >> echo.status
WARNING  >> echo.warning
DEBUG    >> echo.debug
FAIL     >> utils.fail
ABORT    >> utils.abort

CHECK_ERRORS >> utils.check-errors

Yn >> utils.Yn
yN >> utils.yN

EDIT >> utils.io.edit

CHECK_ENVIRONMENT >> utils.check-environment
```

### `zsh/utils` Color Functions

Rather than storing ANSI colors as a variable, colors are now stored as a function which prints the color code.
Doing this has proven more versatile than trying to extract the value of the variable in several contexts.
Rename looks like this for all named ANSI colors:

```bash
$__GREEN      >> utils.colors.green
$__BRIGHT_RED >> utils.colors.bright-red
```

The most common use case of colors is indirectly through the `echo.*` commands, so a new function now provides _the color used by the associated `echo.*` command_:

```bash
# instead of
STATUS "Hello there, ${_BRIGHT_GREEN}bobby${_YELLOW}. How are you?"

# use
echo.status "Hello there, $(utils.colors.bright-green)bobby$(echo.status.color). How are you?
```

### ZSH Scwrypts Module Naming

**This is the biggest point of refactor.**

You will notice that modules now declare their functions using a `${scwryptsmodule}` notation.
This notation provides a dot-notated name which is intended to provide a consistent, unique naming system in ZSH (remember, everything loaded into the same shell script must have a globally-unique name).
Consider the new naming method for the following:

```bash
# v4: zsh/lib/helm/template.module.zsh

HELM__TEMPLATE__GET() {
    # ...
}

# v5: zsh/helm/get-template.module.zsh
${scwryptsmodule}() {
    # ...
}
```

Although the import syntax is generally the same, now we reference the full name of the module instead of the arbitrarily defined `HELM__TEMPLATE__GET`:

```
# in some other scwrypt
use helm/get-template

helm.get-template --raw ./my-helm-chart
```

The name `${scwryptsmodule}` is depended on the scwrypts library path.
Since there is not an easy way to provide an exhaustive list, go through all the places where you `use` something from the scwrypts core library, and check to see where it is now.
One of the critical call-outs is the AWS CLI, which no longer follows the "just use ALL CAPS for function names," but instead is a proper module.

Both of the following are valid ways to use the scwrypts-safe aws-cli (`AWS` in v4):

```bash
# to import _only_ AWS cli
use cloud.aws.cli

cloud.aws.cli sts get-caller-identity

# importing the full AWS module also provides an alias
use cloud.aws

cloud.aws sts get-caller-identity
```

### Great news!

Great news!
We have finished with **all of the necessary steps** to migrate to v5!

If you still have the energy, take some time to make these _recommended_ adjustments too.


### Use the new `${scwryptsmodule}` syntax

The `${scwryptsmodule}` name is now automatically available in any module.
The one change from the `${scwryptsmodule}` in scwrypts core is that **your scwrypts group name is the first dot**.

If I'm building the scwrypts group called `my-cool-stuff` and open the file `my-cool-stuff/zsh/module-a.module.zsh`, then `${scwryptsmodule}` will refer to `my-cool-stuff.module-a`.

### Update your `*.scwrypts.zsh` declaration file

In v4 and earlier, it was tricky to create your own scwrypts group, since you had to create a particular folder structure, and write a `group-name.scwrypts.zsh` file with some somewhat arbitrary requirements.
In v5, you can now make any folder a scwrypts group by simply _creating the `*.scwrypts.zsh` file_.

```bash
# this will turn the current folder into the root of a scwrypts group called `my-cool-stuff`
touch 'my-cool-stuff.scwrypts.zsh'
    ├── zsh
    ├── zx
    └── py
```

Advanced options for scwrypts are now [documented in the example](../../scwrypts.scwrypts.zsh), so please refer to it for any additional changes you may need for existing scwrypts modules.
