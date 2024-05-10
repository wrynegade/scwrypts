#####################################################################

use unittest
testmodule=cloud.aws.eks

#####################################################################

beforeall() {
	use cloud/aws
}

#####################################################################

test.provides-eks-cli() {
	unittest.test.provides ${testmodule}.cli
}

test.provides-eks-cli-alias() {
	unittest.test.provides ${testmodule}
}

test.provides-cluster-login() {
	unittest.test.provides ${testmodule}.cluster-login
}
