#
# common logic used in testing
#

# use uuidgen for random string generation
DEPENDENCIES+=(uuidgen)

# ensure a module provides a function by name
use unittest/test/provides
