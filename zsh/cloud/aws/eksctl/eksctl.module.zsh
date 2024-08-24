#
# module for eksctl actions
#

# context wrapper for direct use of eksctl
use cloud/aws/eksctl/cli
eval "${scwryptsmodule}() { ${scwryptsmodule}.cli \$@; }"

# argument helper for creating a standard iamserviceaccount
use cloud/aws/eksctl/iamserviceaccount
