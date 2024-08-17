#
# library to facilitate loading scwrypts runtime variables from
# user-friendly YAML files or environment variables
#


# allows FZF selection of environments
use scwrypts/environment/selection

# initialize environments, or skip if already initialized
use scwrypts/environment/init

# injects metadata and unifies environment template
use scwrypts/environment/template

# generates local/non-CI configuration
use scwrypts/environment/user

# create/edit/delete operations on local configurations
use scwrypts/environment/update
