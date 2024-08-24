#
# provides utilities for interacting with Amazon Web Services (AWS)
#

# context wrapper for AWS CLI v2
use cloud/aws/cli
eval "${scwryptsmodule}() { ${scwryptsmodule}.cli \$@; }"

# simplify context commands for kubectl on EKS
use cloud/aws/eks

# context wrapper for eksctl
use cloud/aws/eksctl
