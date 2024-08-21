#
# library to facilitate loading scwrypts runtime variables from
# user-friendly YAML files or environment variables
#


# common lookups used by all environment logic
use scwrypts/environment/common


# allows utils.fzf selection of environments
use scwrypts/environment/select-env


# initialize environments, or skip if already initialized
use scwrypts/environment/init


# injects metadata and unifies environment template
use scwrypts/environment/get-full-template


# lookup environment variables by config path
use scwrypts/environment/get-envvar-lookup-map


# generates local/non-CI configuration
use scwrypts/environment/user


# create/edit/delete operations on local configurations
use scwrypts/environment/update
