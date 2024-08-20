# Scwrypts Upgrade v3 to v4 Notes

Scwrypts v4 brings a big update to the *runstring for `zsh`-type scwrypts*.
I've found some of the boilerplate required by each individual script to be confusing and terse, and the goal here is to make it easier and safer to write and run scwrypts in this critical format.

Jump to [Technical Bits](#technical-bits) if you just want to get started with migration steps.
The actual migration _should take less than a minute per script_.
This document is deliberately verbose for future reference when I don't remember how any of this works.

## Ideology and History

Originally (scwrypts v2 and below) wanted to preserve the direct-use of individual scwrypts.
In those versions, executable files could be executed directly (outside of the `scwrypts` function) and still operate with minimal, unwanted consequences.
This resulted in a rigid structure which made code-sharing difficult at small scales and untenable in many non-trivial cases.

Scwrypts v3, begrudgingly introduced a pseudo-import syntax with `use`.
This sought to combat the issues of code-sharing and open up the structure of executable scwrypts to the scwrypts-writer.
Beyond just clarity, this allowed external libraries to be written and cross-referenced.
Although "importing" is an odd (anti?)feature to shell scripting, the way libraries could be written and reused was too helpful and I succumbed to write the `import.driver.zsh` module.


Throughout v3, I tried to maintain the "executability" of individual scwrypts.
It's ugly though.
Every individual scwrypt relies on `import.driver.zsh` and the context set up by the `scwrypts` executable.
While you _could_ run the executable file directly, it would misbehave at-best and fail pretty reliably.

So... here's v4!
Scwrypts v4 accepts the reality that, although `zsh` scwrypts are zsh, they do not stand alone without the proper context setup provided by `scwrypts`.
To improve usability, I've abstracted much of the boilerplate so you never have to see it.
I've injected safety mechanisms like `--help` arguments and utility mechanisms like flag separation (`-abc` is really `-a -b -c`) into all v4 zsh scwrypts.

You don't have to worry about checking the context, v4 does that for you!

You don't have to worry about execution, v4 does that for you!

So!

Are you coupling your zsh scripts to `scwrypts` when you write them? Yes.
Is that a bad thing? I don't think so.
Shell-scripting is such a critical coupler to real-life systems.
High-risk-high-impact to SLAs means we cannot allow context mistakes by sysadmins and users.
Reusability between local machine, cloud runtime, and CI pipelines is a must.
And if you have a need to reign all that in to single, isolated executable files...

...then good luck <3

## Technical Bits

Big idea: let's get rid of v3 boilerplate and make things easy.

### Your executable must be in a MAIN function

A main function in shell scripts?
Weird!
Don't worry, it's easy.

Take your original scwrypt, and slap the executable stuff into a function called `MAIN` (yes, it must be _exactly_, all-caps `MAIN`):

```diff
#!/usr/bin/env zsh
#####################################################################
DEPENDENCIES+=(dep-function-a dep-function-b)
REQUIRED_ENV+=()

use do/awesome/stuff --group my-custom-library

CHECK_ENVIRONMENT
#####################################################################

- echo "do some stuff here"
- # ... etc ...
- echo.success "completed the stuff"
+ MAIN() {
+     echo "do some stuff here"
+     # ... etc ...
+     echo.success "completed the stuff
+ }
```

**Don't invoke the function!**
Scwrypts will now do that on your behalf.
I've already written many scwrypts which _almost_ used this syntax.
All I had to do in this case was delete the function invocation at the end:

```diff
# ... top boilerplate ...
MAIN() {
    echo.success "look at me I'm so cool I already wrote this in a main function"
}
-
- #####################################################################
- MAIN $@
```

Again, **do not invoke the function**. Just name it `MAIN` and you're good-to-go!

### Great news!

Great news!
We have finished with *all of the necessary steps* to migrate to v4!
Easy!

While you're here, let's do a couple more things to cleanup your scwrypts (I promise they are also easy and will take less than a few seconds for each)!

### Remove the boilerplate

Were you confused by all that garbage at the top?
Awesome!
Just get rid of any of it you don't use.

While you _probably_ will still need whatever dependencies you already defined, feel free to get rid of empty config lists like `DEPENDENCIES+=()`.
For non-empty lists, the syntax remains the same (use the `+=` and make sure it's an array-type `()` just like before!)

Also you can ditch the `CHECK_ENVIRONMENT`.
While it won't hurt, v4 already does this, so just get rid of it.
Here's my recommended formatting:
```diff
#!/usr/bin/env zsh
- #####################################################################
DEPENDENCIES+=(dep-function-a dep-function-b)
- REQUIRED_ENV+=()

use do/awesome/stuff --group my-custom-library
- 
- CHECK_ENVIRONMENT
#####################################################################

MAIN() {
    echo "do some stuff here"
    # ... etc ...
    echo.success "completed the stuff
}
```


### Get rid of `--help` argument processing

Scwrypts v4 injects the `--help` argument into every zsh scwrypt.
So there's no need to process it manually anymore!

We can now eliminate the help case from any MAIN body or library function:

```diff
MAIN() {
    while [[ $# -gt 0 ]]
    do
        case $1 in
            # ... a bunch of cases ...
-            -h | --help ) USAGE; return 0 ;;
            # ... a bunch of cases ...
        esac
        shift 1
    done
}
```

While you probably weren't doing this, you can also do the same for any logic which splits arguments input like `-abc` which should be read as `-a -b -c`.
If you know how to do this, you know how to get rid of it.

### Write some help docs

Okay this one might take a little bit of time if you haven't done it already (but this is the last recommended step! hang in there and make your stuff better!).
If you _have_ done it already, typically by writing a variable called "USAGE" in your code, maybe consider the _new and improved_ way to write your help strings.

Returning to our original `MAIN()` example, I'll add some options parsing so we should now look something like this:
```sh
#!/usr/bin/env zsh
DEPENDENCIES+=(dep-function-a dep-function-b)

use do/awesome/stuff --group my-custom-library
#####################################################################

MAIN() {
    local A
    local B=false
    local ARGS=()

    while [[ $# -gt 0 ]]
    do
        case $1 in
            -a | --option-a ) A=$2; shift 1 ;;

            -b | --allow-b ) B=true ;;

            * ) ARGS+=($1) ;;
        esac
        shift 1
    done

    echo "A : $A\nB : $B\nARGS : $ARGS"
}
```

All we have to do is add some usage variables and we're done!
I want to call out a few specific ones:
- `USAGE__options` provides descriptions for CLI flags like `-a` `--some-flag` and `-a <some value>` (reminder, you *don't* need '-h, --help' anymore!)
- `USAGE__args` provides descriptions for non-flag CLI arguments, where order matters (e.g. `cat file-a file-b ... etc`)
- `USAGE__description` provides the human-readable description of what your function does
- `USAGE__usage` you probably don't need to adjust this one, but it will be everything after the `--` in the usage-line. Defaults to include `[...options...]`, but I suppose you might want to write `USAGE__usage+=' [...args...]` if you 1) have args and 2) are really specific about your help strings.

Just add another section to define these values before declaring `MAIN`:
```sh
#!/usr/bin/env zsh
DEPENDENCIES+=(dep-function-a dep-function-b)

use do/awesome/stuff --group my-custom-library
#####################################################################

USAGE__options='
  -a, --option-a <string>   sets the value of the A variable
  -b, --allow-b             enables the B option
'

# remember there's no specific formatting here, just write it nice
USAGE__args='
  N-args   All remaining args are inserted into the ARGS variable
'

USAGE__description="
    This is my cool example function. It's really neato, but does
    very little.
"

#####################################################################

MAIN() {
    # ... etc ...
}

```

Now, when we run `scwrypts my sample -- --help`, we get:
```txt
usage: scwrypts my sample -- [...options...]

args:
  N-args   All remaining args are inserted into the ARGS variable

options:
  -a, --option-a <string>   sets the value of the A variable
  -b, --allow-b             enables the B option

  -h, --help   display this message and exit

This is my cool example function. It's really neato, but does
very little.
```

### All done

No more recommendations at this time.
Someday I'll have an auto-formatter and a language server to help with go-to-definition, but that's still for the future.

Thanks for your time and welcome to v4!
