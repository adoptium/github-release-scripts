#!/bin/bash
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
#

###################################################################
#
# PublishDevKit.sh TAG <GITHUB_SERVER> <GITHUB_ORG>
#
# This script will take the passed in TAG
# then use a Groovy scripy with the Github API to create a
# release (or update an existing release) up in GitHub 
#
###################################################################
set -eo pipefail

# eg: artifact:
# devkit-gcc-11.3.0-Centos7.6.1810-x86_64-linux-gnu-b01.tar.gz

#              (compiler    )  (version      ) (sysroot       ) (arch          )(suffix    ) (build       )  (extension                                )
regex="^devkit-([[:alnum:]]+)-([[:digit:]\.]+)-([[:alnum:]\.]+)-([[:alnum:]\_]+)(-linux-gnu)-([[:alnum:]]+)\.(tar\.xz|tar\.xz\.sha256\.txt|tar\.xz\.sig)$";

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
for file in devkit-*
  do
    if [[ $file =~ $regex ]];
    then
      echo "DevKit file: $file"
      FILE_COMPILER=${BASH_REMATCH[1]};
      FILE_VERSION=${BASH_REMATCH[2]};
      FILE_SYSROOT=${BASH_REMATCH[3]};
      FILE_ARCH=${BASH_REMATCH[4]};
      FILE_SUFFIX=${BASH_REMATCH[5]};
      FILE_BUILD=${BASH_REMATCH[6]};
      FILE_EXTENSION=${BASH_REMATCH[7]};

      file_tag="${FILE_COMPILER}-${FILE_VERSION}-${FILE_SYSROOT}-${FILE_BUILD}"

      # Validate tarball is valid for publishing as TAG release
      if [[ "${file_tag}" != "${TAG}" ]]; then
        echo "${file_tag}"
        echo "ERROR: devkit file is not valid for publishing under release tag ${TAG} : ${file}"
        valid_files=false
      fi
    else
      echo "ERROR: devkit file does not match required regex pattern: ${file}" 
      valid_files=false
    fi
  done

if [ "$valid_files" == "false" ]; then
  echo "ERROR: Some devkit filenames are not valid..."
  exit 1
fi

files=$(find $PWD \( -name "devkit-*" \) | tr '\n' ' ')

if [ "$DRY_RUN" == "false" ]; then
  description="Release of $TAG"

  # Hand over to the Groovy script that uses the GitHub API to actually create the release and upload files
  cd adopt-github-release || exit 1
  chmod +x gradlew
  GRADLE_USER_HOME=./gradle-cache ./gradlew --no-daemon run --args="--isDevKit --release --version \"${TAG}\" --tag \"${TAG}\" --description \"${description}\" ${server} ${org} $files"
fi

