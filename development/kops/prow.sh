#!/usr/bin/env bash
# Copyright 2020 Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ "$AWS_ROLE_ARN" == "" ]; then
    echo "Empty AWS_ROLE_ARN, this script must be run in a postsubmit pod with IAM Roles for Service Accounts"
    exit 1
fi

if [ "$TEST_ROLE_ARN" == "" ]; then
    echo "Empty AWS_ROLE_ARN, this script must be run in a postsubmit pod with IAM Roles for Service Accounts"
    exit 1
fi

BASEDIR=$(dirname "$0")

cat << EOF > config
[default]
output=json
region=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}
role_arn=$AWS_ROLE_ARN
web_identity_token_file=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

[profile conformance-test]
role_arn=$TEST_ROLE_ARN
region=${AWS_REGION:-${AWS_DEFAULT_REGION:-us-west-2}}
source_profile=default
EOF
export AWS_CONFIG_FILE=$(pwd)/config
export AWS_PROFILE=conformance-test
unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE
export KOPS_CLUSTER_NAME=${PROW_JOB_ID}.prod.test.pdx.kops-ci.model-rocket.aws.dev
${BASEDIR}/run_all.sh