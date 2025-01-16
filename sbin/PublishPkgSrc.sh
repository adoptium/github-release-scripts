#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#

###################################################################
#
# PublishPkgSrc.sh TAG <GITHUB_SERVER> <GITHUB_ORG>
#
# Updated Filename Validation Logic
#
###################################################################
set -eo pipefail

# Validate filenames matching: Package_Bld_Src_ + (linux|alpine-linux) + jdk<anything> + .tar.gz
regex="^Package_Bld_Src_(linux|alpine-linux)_jdk.*\.tar\.gz$"

# Check that a TAG has been passed in.
if [ -z "${TAG}" ]; then
    echo "Must have a tag set"
    exit 1
fi

# Set the GitHub server to push to
if [ -z "${GITHUB_SERVER}" ]; then
   server=""
else
   server="--server \"${GITHUB_SERVER}\""
fi

# Set the GitHub org to push to
if [ -z "${GITHUB_ORG}" ]; then
   org=""
else
   org="--org \"${GITHUB_ORG}\""
fi

# Validate all file names with regex
valid_files=true
for file in Package_Bld_Src_*
do
    if [[ $file =~ $regex ]]; then
        echo "Valid file: $file"
    else
        echo "ERROR: File does not match the required pattern: ${file}"
        valid_files=false
    fi
done

if [ "$valid_files" == "false" ]; then
    echo "ERROR: Some filenames are not valid..."
    exit 1
fi

files=$(find $PWD \( -name "Package_Bld_Src_*" \) | tr '\n' ' ')
description="Release of $TAG"
# Hand over to the Groovy script that uses the GitHub API to actually create the release and upload files
cd adopt-github-release || exit 1
chmod +x gradlew
GRADLE_USER_HOME=./gradle-cache ./gradlew --no-daemon run --args="--isPkgSrc --release --version \"${TAG}\" --tag \"${TAG}\" --description \"${description}\" ${server} ${org} $files"
