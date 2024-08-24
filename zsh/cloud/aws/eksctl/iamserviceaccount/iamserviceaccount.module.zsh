#
# build 'iamserviceaccount' to enable IAM identity / access control
#

# create the iamserviceaccount
use cloud/aws/eksctl/iamserviceaccount/create

# check whether the iamserviceaccount exists in kubernetes
use cloud/aws/eksctl/iamserviceaccount/check-exists
