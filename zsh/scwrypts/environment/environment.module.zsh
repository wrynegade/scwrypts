#
# library to facilitate loading scwrypts runtime variables from
# user-friendly YAML files or environment variables
#


# common lookups used by all environment logic
use scwrypts/environment/common

# primary source of truth for configuration values in the environment
use scwrypts/environment/get-user-json

# initialize environments, or skip if already initialized
use scwrypts/environment/init

# allows utils.fzf selection of environments
use scwrypts/environment/select-env

# creates a merged template file across all known scwrypts groups' env.yaml
use scwrypts/environment/get-full-template

# create/edit/delete operations on local configurations
use scwrypts/environment/update
