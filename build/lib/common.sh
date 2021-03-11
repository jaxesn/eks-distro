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


function build::common::ensure_tar() {
  if [[ -n "${TAR:-}" ]]; then
    return
  fi

  # Find gnu tar if it is available, bomb out if not.
  TAR=tar
  if which gtar &>/dev/null; then
      TAR=gtar
  elif which gnutar &>/dev/null; then
      TAR=gnutar
  fi
  if ! "${TAR}" --version | grep -q GNU; then
    echo "  !!! Cannot find GNU tar. Build on Linux or install GNU tar"
    echo "      on Mac OS X (brew install gnu-tar)."
    return 1
  fi
}

# Build a release tarball.  $1 is the output tar name.  $2 is the base directory
# of the files to be packaged.  This assumes that ${2}/kubernetes is what is
# being packaged.
function build::common::create_tarball() {
  build::common::ensure_tar

  local -r tarfile=$1
  local -r stagingdir=$2
  local -r repository=$3

  "${TAR}" czf "${tarfile}" -C "${stagingdir}" $repository --owner=0 --group=0
}

# Generate shasum of tarballs. $1 is the directory of the tarballs.
function build::common::generate_shasum() {

  local -r tarpath=$1

  echo "Writing artifact hashes to shasum files..."

  if [ ! -d "$tarpath" ]; then
    echo "  Unable to find tar directory $tarpath"
    exit 1
  fi

  cd $tarpath
  for file in $(find . -name '*.tar.gz'); do
    filepath=$(basename $file)
    sha256sum "$filepath" > "$file.sha256"
    sha512sum "$filepath" > "$file.sha512"
  done
  cd -
}


function build::gather_licenses() {
  local -r outputdir=$1
  local -r patterns=$2

  mkdir -p "${outputdir}/attribution"
  # attribution file generated uses the output go-deps and go-license to gather the neccessary
  # data about each dependency to generate the amazon approved attribution.txt files
  # go-deps is needed for module versions
  # go-licenses are all the dependencies found from the module(s) that were passed in via patterns
  go list -deps=true -json ./... | jq -s ''  > "${outputdir}/attribution/go-deps.json"
  
  go-licenses save --force $patterns --save_path="${outputdir}/LICENSES"
  
  # go-licenses can be a bit noisy with its output and lot of it can be confusing 
  # the following messags are safe to ignore since we do not need the license url for our process
  NOISY_MESSAGES="cannot determine URL for|Error discovering URL|unsupported package host"
  go-licenses csv $patterns > "${outputdir}/attribution/go-license.csv" 2>  >(grep -vE "$NOISY_MESSAGES" >&2)

  # go-license is pretty eager to copy src for certain license types
  # when it does, it applies strange permissions to the copied files
  # which makes deleting them later awkward
  # this may change in the future with the following PR
  # https://github.com/google/go-licenses/pull/28
  #
  chmod -R 777 "${outputdir}/LICENSES"  

  # most of the packages show up the go-license.csv file as the module name
  # from the go.mod file, storing that away since the source dirs usually get deleted
  MODULE_NAME=$(go mod edit -json | jq -r '.Module.Path')
  echo $MODULE_NAME > ${outputdir}/attribution/root-module.txt
}

function build::generate_attribution() {
  local -r clone_url=$1

  GOLANG_VERSION_TAG=$(go version | grep -o "go[0-9].* ")

  generate-attribution $clone_url $GOLANG_VERSION_TAG
}

function build::generate_and_diff_attribution(){
  local -r project_root=$1
  local -r golang_verson=$2
  local -r root_module_name=${3:-$(cat ${project_root}/_output/attribution/root-module.txt)}

  build::common::use_go_version $golang_verson

  build::generate_attribution $root_module_name
  build::diff_attribution "${project_root}/ATTRIBUTION.txt" "${project_root}/_output/attribution/ATTRIBUTION.txt"
}

function build::diff_attribution() {
  local -r existing=$1
  local -r new=$2

  diff $existing $new > /dev/null 2>&1 || error=$? 
  if [ -n "${error-}" ]
  then
    echo "The newly generated ATTRIBUTION.txt is different than previous version."
    echo "Please validate the difference and check in the new version."
    exit $error
  fi  
}

function build::common::use_go_version() {
  local -r version=$1
  local gobinaryversion=""

  if [[ $version == "1.13"* ]]; then
    gobinaryversion="1.13"
  fi
  if [[ $version == "1.14"* ]]; then
    gobinaryversion="1.14"
  fi
  if [[ $version == "1.15"* ]]; then
    gobinaryversion="1.15"
  fi

  if [[ "$gobinaryversion" == "" ]]; then
    return
  fi

  # This is the path where the specific go binary versions reside in our builder-base image
  local -r gobinarypath=/go/go${gobinaryversion}/bin
  echo "Adding $gobinarypath to PATH"
  # Adding to the beginning of PATH to allow for builds on specific version if it exists
  export PATH=${gobinarypath}:$PATH
}

function build::common::re_quote() {
    local -r to_escape=$1
    sed 's/[][()\.^$\/?*+]/\\&/g' <<< "$to_escape"
}