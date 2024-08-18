#
# provides utilities for interacting with Amazon Web Services (AWS)
#

use cloud/aws/cli  # ./cli.module.zsh
eval "${scwryptsmodule}() { ${scwryptsmodule}.cli \$@; }"

use cloud/aws/eks  # ./eks/eks.module.zsh
