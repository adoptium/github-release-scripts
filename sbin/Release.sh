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
# Release.sh TAG <RELEASE> <TIMESTAMP> <GITHUB_SERVER> <GITHUB_ORG>
#
# This script will take the passed in TAG, rename the files 
# in accordance with our consistent timestamp policy and 
# then use a Groovy scripy with the Github API to create a
# release (or update an existing release) up in GitHub 
#
# TODO We could probably use some functions in here and better 
# documentation of the variables using the POSIX standard
#
###################################################################

# Our timestamps must fit this particular format: YYYY-DD-MM-hh-mm, e.g. 2021-07-30-16-11
timestampRegex="[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}"

# IF YOU ARE MODIFYING THIS THEN THE FILE MATCHING IS PROBABLY WRONG, MAKE SURE adoptium/api.adoptium.net and adoptopenjdk/openjdk-api, ARE UPDATED TOO
#      OpenJDK 8U_             -jdk        x64_           Linux_         hotspot_         2018-06-15-10-10                .tar.gz
#      OpenJDK 11_             -jdk        x64_           Linux_         hotspot_         11_28                           .tar.gz
regex="OpenJDK([[:digit:]]+)U?(-jre|-jdk)_([[:alnum:]\-]+)_([[:alnum:]]+)_([[:alnum:]]+).*\.(tar\.gz|zip|pkg|msi)";
regexArchivesOnly="${regex}$";

# Check that a TAG, e.g. jdk11.0.12+7, has been passed in.
# Note we deliberately do not cehck the format of the tag for flexibility sake
if [ -z "${TAG}" ]; then
    echo "Must have a tag set"
    exit 1
fi

# Nightlies must have a TIMESTAMP.
if [ "$RELEASE" == "false" ] && [ -z "${TIMESTAMP}" ]; then
    echo "Nightly must have a TIMESTAMP set"
    exit 1
fi

# Set the GITHUB SERVER if we have one
if [ -z "${GITHUB_SERVER}" ]; then
   server=""
else
   server="--server \"${GITHUB_SERVER}\""
fi

# Set the GITHUB_ORG if we have one
if [ -z "${GITHUB_ORG}" ]; then
   org=""
else
   org="--org \"${GITHUB_ORG}\""
fi

# Rename to ensure a consistent timestamp across release
for file in OpenJDK*
do
  echo "Processing $file";

  if [[ $file =~ $regexArchivesOnly ]];
  then
    newName=$(echo "${file}" | sed -r "s/${timestampRegex}/$TIMESTAMP/")

    if [ "${file}" != "${newName}" ]; then
      # Rename archive and checksum file with new timestamp
      echo "Renaming ${file} to ${newName}"
      mv "${file}" "${newName}"
      mv "${file}.sha256.txt" "${newName}.sha256.txt"
      mv "${file}.json" "${newName}.json"
    fi

    # Fix checksum file name
    strippedFileName=$(echo "${newName}" | sed -r "s/.+\\///g")
    sed -i -r "s/^([0-9a-fA-F ]+).*/\1${strippedFileName}/g" "${newName}.sha256.txt"

    FILE_VERSION=${BASH_REMATCH[1]};
    FILE_TYPE=${BASH_REMATCH[2]};
    FILE_ARCH=${BASH_REMATCH[3]};
    FILE_OS=${BASH_REMATCH[4]};
    FILE_VARIANT=${BASH_REMATCH[5]};
    FILE_TS_OR_VERSION=${BASH_REMATCH[6]};
    FILE_EXTENSION=${BASH_REMATCH[8]};

    echo "version:${FILE_VERSION} type: ${FILE_TYPE} arch:${FILE_ARCH} os:${FILE_OS} variant:${FILE_VARIANT} timestamp or version:${FILE_TS_OR_VERSION} timestamp:${TIMESTAMP} extension:${FILE_EXTENSION}";
  fi
done

# TODO - shellcheck (SC2012) tells us that using find is better than ls here.
files=$(ls "$PWD"/OpenJDK*{.tar.gz,.sha256.txt,.zip,.pkg,.msi,.json} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g')

echo ""
echo "RELEASE flag is set to: $RELEASE"
echo ""

RELEASE_OPTION=""
if [ "$RELEASE" == "true" ]; then
  description="Official Release of $TAG"
  RELEASE_OPTION="--release"
else
  # -beta is a special designation that we must use to indicate non GA (non TCK'd) builds.
  TAG="${TAG}-beta"
  description="Nightly Build of $TAG"
fi

# Hand over to the Groovy script that uses the GitHub API to actually create the release and upload files
if [ "$DRY_RUN" == "false" ]; then
    cd adopt-github-release || exit 1
    chmod +x gradlew
    GRADLE_USER_HOME=./gradle-cache ./gradlew --no-daemon run --args="--version \"${VERSION}\" --tag \"${TAG}\" --description \"${description}\" ${server} ${org} $RELEASE_OPTION $files"
fi
