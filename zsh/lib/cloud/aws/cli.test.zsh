#####################################################################

use test/unittest
use test/mock

use cloud/aws/cli

#####################################################################

AWS.test.forwards_arguments() {
	MOCK DEBUG
	MOCK aws
	MOCK__ENV AWS_PROFILE --value $(uuidgen)
	MOCK__ENV AWS_PROFILE --value $(uuidgen)

	AWS 

	aws.assert.calledwith 'asdf'
}
