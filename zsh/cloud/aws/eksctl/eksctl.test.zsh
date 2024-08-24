#####################################################################

use unittest
testmodule=cloud.aws.eksctl

#####################################################################

beforeall() {
	use cloud/aws/eksctl
}

#####################################################################

test.provides-eksctl-cli() {
	unittest.test.provides ${testmodule}.cli
}

test.provides-eksctl-alias() {
	unittest.test.provides ${testmodule}
}
