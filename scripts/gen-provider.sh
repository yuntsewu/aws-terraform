#!/bin/bash
#
# Init variables and sanity checks
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$(dirname $DIR)
BUILD=${BUILD:-$ROOT_DIR/build}

AWS_PROFILE=${AWS_PROFILE:-coreos-cluster}
CLUSTER_NAME=${CLUSTER_NAME:-coreos-cluster}

#TF_VAR_aws_region=$($DIR/read_cfg.sh $HOME/.aws/config "profile $AWS_PROFILE" region)
aws_user=$(aws --profile $AWS_PROFILE iam get-user)
TF_VAR_aws_account=$(echo $aws_user | jq ".User.Arn" | grep -Eo '[[:digit:]]{12}')
TF_VAR_aws_user=$(echo $aws_user | jq --raw-output '.User.UserName')
ALLOW_SSH_CIDR="$(curl -s http://ipinfo.io/ip)/32"

cat <<EOF
# Generated by scripts/gen-provider.sh
provider "aws" {
  profile = "$AWS_PROFILE"
  max_retries = 3
EOF
if [ ! -z $ALLOWED_ACCOUNT_IDS ]; then
    echo  \ \ allowed_account_ids = [ "$ALLOWED_ACCOUNT_IDS" ]
elif [[ ! -z $FORBIDDEN_ACCOUNT_IDS ]]; then
    echo  \ \ forbidden_account_ids = [ "$FORBIDDEN_ACCOUNT_IDS" ]
fi
cat <<EOF
}
variable "aws_account" {
    default = {
        id = "$TF_VAR_aws_account"
        default_region = "$AWS_REGION"
    }
}
variable "cluster_name" {
    default = "${CLUSTER_NAME}"
}
variable "build_dir" {
    default = "${BUILD}"
}
variable "allow_ssh_cidr" {
    default = "${ALLOW_SSH_CIDR}"
}
EOF
