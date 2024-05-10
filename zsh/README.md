# ZSH Scwrypts
[![Generic Badge](https://img.shields.io/badge/1password-op-informational.svg)](https://1password.com/downloads/command-line)
[![Generic Badge](https://img.shields.io/badge/BurntSushi-rg-informational.svg)](https://github.com/BurntSushi/ripgrep)
[![Generic Badge](https://img.shields.io/badge/dbcli-pgcli-informational.svg)](https://github.com/dbcli/pgcli)
[![Generic Badge](https://img.shields.io/badge/junegunn-fzf-informational.svg)](https://github.com/junegunn/fzf)
[![Generic Badge](https://img.shields.io/badge/mikefarah-yq-informational.svg)](https://github.com/mikefarah/yq)
[![Generic Badge](https://img.shields.io/badge/stedolan-jq-informational.svg)](https://github.com/stedolan/jq)
<br>

Since they emulate direct user interaction, shell scripts are a (commonly dreaded) go-to for automation.

Although the malleability of shell scripts can make integrations quickly, the ZSH-type scwrypt provides a structure to promote extendability and clean code while performing a lot of the heavy lifting to ensure consistent execution across different runtimes.

## The Basic Framework

Take a look at the simplest ZSH-type scwrypt: [hello-world](./hello-world).
The bare minimum API for ZSH-type scwrypts is to:

1. include the shebang `#!/usr/bin/env zsh` on the first line of the file
2. wrap your zsh in a function called `MAIN()`
3. make the file executable (e.g. `chmod +x hello-world`)

Once this is complete, you are free to simply _write valid zsh_ then execute the scwrypt with `scwrypts hello world zsh`!

## Basics+

While it would be perfectly fine to use the `echo` function in our scwrypt, you'll notice that the `hello-world` scwrypt instead uses `echo.success` which is _not_ valid ZSH by default.
This is a helper function provided by the scwrypts ZSH library, and it does a lot more work than you'd expect.

Although this function defaults to print user messages in color, notice what happens when you run `scwrypts --output json hello world zsh`:

```json
{"timestamp":1745674060,"runtime":"c62737da-481e-4013-a370-4dedc76bf4d2","scwrypt":"start of hello-world scwrypts zsh","logLevel":"3","subscwrypt":0}
{"timestamp":1745674060,"runtime":"c62737da-481e-4013-a370-4dedc76bf4d2","status":"SUCCESS","message":"\"Hello, World!\""}
{"timestamp":1745674060,"runtime":"c62737da-481e-4013-a370-4dedc76bf4d2","status":"SUCCESS","message":"\"terminated with code 0\""}
```

We get a LOT more information.

It's 100% possible for you to include your own take on printing messages, but it is highly recommended to use the tools provided here.

### What is loaded by default?

By default, every ZSH-type scwrypt will load [the basic utilities suite](./utils), which is a little different from scwrypts ZSH modules, and a little bit complex.
Although it's totally worth a deep-dive, here are the fundamentals you should ALWAYS use:

#### Printing User Messages or Logs

Whenever you want to print a message to the user or logs, rather than using `echo`, use the following:
<!------------------------------------------------------------------------>
| function name   | minimum log level | description                       |
| --------------- | ----------------- | --------------------------------- |
| `echo.success`  |                 1 | indicate successful completion    |
| `echo.error`    |                 1 | indicate an error has occurred    |
| `echo.reminder` |                 1 | an important, information message |
| `echo.status`   |                 2 | a regular, information message    |
| `echo.warning`  |                 3 | a non-critical warning            |
| `echo.debug`    |                 4 | a message for scwrypt developers  |
<!------------------------------------------------------------------------>

Of the `echo` family, there are two unique functions:

- `echo.error` will **increment the `ERRORS` variable** then return an error code of `$ERRORS` (this makes it easy to chain with command failure by using `||`)
- `echo.debug` will inject state information like the timestamp and current function stack


#### Yes / No Prompts

The two helpers `utils.Yn` and `utils.yN` take a user-friendly yes/no question as an argument.

- when the user responds "yes", the command returns 0 / success / `&&`
- when the user responds "no", the command returns 1 / error / `||`
- when the user responds with _nothing_ (e.g. just presses enter), the _default_ is used

The two commands work identically; however, the capitalization denotes the default:
- `utils.Yn` = default "yes"
- `utils.yN` = default "no"

#### Select from a List Prompt

When you want the user to select an item from a list, scwrypts typically use `fzf`.
There are a LOT of options to `fzf`, so there are two provided helpers.

The basic selector, `utils.fzf` (most of the time, you want to use this one) which outputs:
- _the selection_ if the user made a choice
- _nothing / empty string_ if the user cancelled or made an invalid choice

The user-input selector, `utils.fzf.user-input` which outputs:
- _the selection_ if the user made a choice
- _the text typed by the user_ if the user typed something other than the listed choices
- _nothing / empty string_ if the user cancelled
- _a secondary `utils.fzf` prompt_ if the user's choice was ambiguous

### Imports

Don't use `source` in ZSH-type scwrypts (I mean, if you're pretty clever you can get it to work, but DON'T THOUGH).
Instead, use `use`!

The `use` command, rather than specifying file directories, you reference the path to `*.module.zsh`.
This means you don't have to know the exact path to any given file.
For example, if I wanted to import the safety tool for `aws` CLI commands, I can do the following:

```zsh
#!/usr/bin/env zsh

use cloud/aws

#####################################################################

MAIN() {
    cloud.aws sts get-caller-identity
}
```
