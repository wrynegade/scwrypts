#
# function mocking utilities for ZSH unit testing
#

# primary mock generator
use unittest/mock/create
eval "${scwryptsmodule}() { ${scwryptsmodule}.create \$@; }"

# mock environment variables
use unittest/mock/env
