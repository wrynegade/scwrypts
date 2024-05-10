#
# run kubectl/helm/etc commands on AWS Elastic Kubernetes Service (EKS)
#

# provides an EKS connection wrapper for any kubectl-like cli
use cloud/aws/eks/cli
eval "${scwryptsmodule}() { ${scwryptsmodule}.cli $@; }"

# sets up kubeconfig to connect to EKS
use cloud/aws/eks/cluster-login
