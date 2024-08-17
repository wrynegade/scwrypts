#####################################################################

use unittest
testmodule=cloud.aws

#####################################################################

beforeall() {
	use cloud/aws
}

#####################################################################

test.provides-aws-cli() {
	unittest.test.provides ${testmodule}.cli
}

test.provides-aws-cli-alias() {
	unittest.test.provides ${testmodule}
}

test.provides-eks() {
	unittest.test.provides ${testmodule}.eks
}
