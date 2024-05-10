#####################################################################

use unittest
testmodule=cloud.aws.eksctl.iamserviceaccount

#####################################################################

beforeall() {
	use cloud/aws/eksctl/iamserviceaccount
}

#####################################################################

test.provides-create() {
	unittest.test.provides ${testmodule}.create
}

test.provides-check-exists() {
	unittest.test.provides ${testmodule}.check-exists
}
