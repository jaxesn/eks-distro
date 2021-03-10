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

set -o errexit
set -o nounset
set -o pipefail

MAKE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${MAKE_ROOT}/../../../build/lib/common.sh"

CLONE_URL="$1"
GOLANG_VERSION="$2"

OUTPUT_DIR="${OUTPUT_DIR:-${MAKE_ROOT}/_output}"
build::common::use_go_version $GOLANG_VERSION

# go-licenses calls the main module command-line-arguments
sed -i.bak 's/^command-line-arguments/k8s.io\/release\/images\/build\/go-runner/' "${OUTPUT_DIR}/attribution/go-license.csv"
build::generate_attribution 'k8s.io/release/images/build/go-runner'
