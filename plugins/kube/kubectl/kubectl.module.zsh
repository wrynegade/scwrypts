#
# combines kubectl with redis to both facilitate use of kubectl
# between varying contexts/namespaces AND grant persistence between
# terminal sessions
#

# redis wrapper for kubectl
use --group kube kubectl/cli

# simplify commands for kubecontexts
use --group kube kubectl/context

# simplify commands for namespaces
use --group kube kubectl/namespace

# local redirect commands for remote kubernetes services
use --group kube kubectl/service
