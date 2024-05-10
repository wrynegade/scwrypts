#####################################################################

use unittest
testmodule=cloud.aws.ecr

#####################################################################

beforeall() {
	use cloud/aws/ecr
}

#####################################################################

test.provides-ecr-login() {
	unittest.test.provides ${testmodule}.login
}
