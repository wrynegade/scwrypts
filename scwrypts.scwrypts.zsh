#
# configuration for a scwrypts "group" or "plugin"
#

# this file defines the configuration for the 'scwrypts' group which
# is required for proper operation, but otherwise loads exactly like
# any other group/plugin

#
# both ${scwryptsgroup} and ${scwryptsgrouproot} are set automatically
#
# ${scwryptsgroup} is determined by the filename 'NAME.scwrypts.zsh'
#
# NAME must be unique and match : ^[a-z][a-z0-9_]*[a-z0-9]$
#  - STARTS with a lower letter
#  - ENDS   with a lower letter or number
#  - contains only lower-alphanumeric and underscores
#  - is at least two characters long
#
# ${scwryptsgrouproot} is automatically set as the parent directory
# /path/to/group-source           <-- this will be ${scwryptsgrouproot}
#   ├── groupname.scwrypts.zsh
#   └── your-scwrypts-source-here
#

#####################################################################
### REQUIRED CONFIGURATION ##########################################
#####################################################################

# Currently, no configuration is required; simply creating the
# groupname.scwrypts.zsh is sufficient to define a new group


#####################################################################
### OPTIONAL CONFIGURATION ##########################################
#####################################################################

readonly ${scwryptsgroup}__type=
#
# ${scwryptsgroup}__type (optional) (default = not set)
#
# used when only one scwrypt "type" (e.g. 'zsh' or 'py') is declared
# in the group
#
# WHEN THIS IS SET, scwrypts will lookup executables starting from the
# base directory (using type ${scwryptsgroup}__type):
#
# /path/to/group-source
#   ├── groupname.scwrypts.zsh
#   ├── valid-scwrypts-executable
#   └── some-other
#       ├── valid-scwrypts-executable
#       └── etc
#
# when this is NOT set, scwrypts must be nested inside a directory
# which matches the type name
#
# /path/to/group-source
#   ├── groupname.scwrypts.zsh
#   │
#   ├── zsh
#   │   ├── valid-scwrypts-executable
#   │   └── some-other
#   │       ├── valid-scwrypts-executable
#   │       └── etc
#   │
#   └── py
#       ├── valid-scwrypts-executable.py
#       └── some-other
#           ├── valid-scwrypts-executable.py
#           └── etc
#


readonly ${scwryptsgroup}__color=$(utils.colors.green)
#
# ${scwryptsgroup}__color (optional) (default = no color / regular text color)
#
# an ANSI color sequence which determines the color of scwrypts in
# interactive menus
#


readonly ${scwryptsgroup}__zshlibrary=
#
# ${scwryptsgroup}__zshlibrary (optional) (default = *see below*)
#
# allows arbitrary 'use module/name --group groupname' imports
# within zsh-type scwrypts
#
# usually this is set at or within ${scwryptsgrouproot}
#
# by default, this uses either:
#  1. ${scwryptsgrouproot}/zsh/lib (compatibility)
#  2. ${scwryptsgrouproot}/zsh     (preferred)
#


readonly ${scwryptsgroup}__virtualenv_path="${SCWRYPTS_STATE_PATH}/virtualenv"
#
# ${scwryptsgroup}__virtualenv_path
#   (optional)
#   (default = ~/.local/state/scwrypts/virtualenv)
#
# defines the path in which virtual environments are stored for
# the group
#


readonly ${scwryptsgroup}__required_environment_regex=
#
# ${scwryptsgroup}__required_environment_regex (optional) (default = allow any)
#
# helps isolate environment by locking group execution to
# environment names which match the regex
#
# when not set, no environment name restrictions are enforced
#
# when set, interactive menus will be adjusted and non-interactive
# execution will fail if the name of the environment does not match
#


#####################################################################
### ADVANCED CONFIGURATION ##########################################
#####################################################################

#${scwryptsgroup}.list-available() {}
#
# ${scwryptsgroup}.list-available()
#
# a function which outputs lines of "${SCWRYPT_TYPE}/${SCWRYPT_NAME}"
# to stdout
#
# by default, looks for executable files in ${scwryptsgrouproot}
#
# during execution of this function, the following variables are
# available:
#
# - $GROUP_ROOT : USE THIS instead of ${scwryptsgrouproot}
# - $GROUP_TYPE : USE THIS instead of ${scwryptsgroup}__type
#
# (see ./zsh/scwrypts/list-available.module.zsh for more details)
#


#${scwryptsgroup}.TYPE.get-runstring() {}
#
# a function which outputs what should be literally run when executing
# the indicated type; scwrypts already implements runstring generators
# for supported types (that's the main thing which makes them "supported")
#
# configuration variables are still automatically included as a
# prefix to the runstring
#
# (see ./zsh/scwrypts/get-runstring.module.zsh for more details)
#


#####################################################################
### HYPER-ADVANCED CONFIGURATION ####################################
#####################################################################

#
# additional zsh can be defined or run arbitrarily; this is NOT recommended
# unless you understand the implications of the various places where
# this code is loaded
#
# if you want to know where to get started (it will take some learning!),
# review the execution process in:
#   - ./scwrypts
#   - ./zsh/scwrypts/get-runstring.module.zsh
#   - ./zsh/scwrypts/environment/user.module.zsh
#
