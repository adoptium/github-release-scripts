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
set -eo pipefail

# Our timestamps must fit this particular format: YYYY-DD-MM-hh-mm, e.g. 2021-07-30-16-11
timestampRegex="[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}"

# IF YOU ARE MODIFYING THIS THEN THE FILE MATCHING IS PROBABLY WRONG, MAKE SURE adoptium/api.adoptium.net and adoptopenjdk/openjdk-api, ARE UPDATED TOO
#      OpenJDK 8U_             -jdk        x64_           linux_         hotspot_         2018-06-15-10-10                .tar.gz
#      OpenJDK 11_             -jdk        x64_           linux_         hotspot_         11_28                           .tar.gz
#      OpenJDK 18_             -testimage  x64_           linux_         hotspot_         18.0.1_10                       .tar.gz
#      OpenJDK 8U_             -testimage  x64_           linux_         hotspot_         8u332b09                        .tar.gz
#      OpenJDK 18U             -jdk-sources                                               2020-06-06-16-36                .tar.gz
#      OpenJDK 11_             -jdk        x64_           linux_         _fast_startup_   11_28                           .tar.gz
#      OpenJDK                 -debugimage aarch64_       linux_         hotspot_         2023-02-16-12-32                .tar.gz
#      OpenJDK 17U_            -jdk        x64_           linux_         hotspot_         17.0.10_5-ea                    .tar.gz
#
#             (version     )  (type                                                                                           ) (arch           ) (os             ) (variant         ) (timestamp     or version        )  (extension          )
regex="OpenJDK([[:digit:]]*)U?(-jre|-jdk|-debugimage|-static-libs-glibc|-static-libs|-static-libs-musl|-testimage|-jdk-sources)_([[:alnum:]\-]+_)?([[:alnum:]\-]+_)?([[:alnum:]\-_]+_)?([[:digit:]\-]+|[[:alnum:]\._\-]+)\.(tar\.gz|zip|pkg|msi)";

regexArchivesOnly="${regex}$";

# Check that a TAG, e.g. jdk11.0.12+7, has been passed in.
# Note we deliberately do not check the format of the tag
if [ -z "${TAG}" ]; then
    echo "Must have a tag set"
    exit 1
fi

# Nightlies must have a TIMESTAMP.
if [ "$RELEASE" == "false" ] && [ -z "${TIMESTAMP}" ]; then
    echo "Nightly must have a TIMESTAMP set"
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

if [ "$UPLOAD_TESTRESULTS_ONLY" == "false" ]; then
  # Rename archive files (and their associated files: checksum, metadata, sig) to ensure a consistent timestamp across release
  for file in OpenJDK*
  do
    # If file name is an archive rename timestamp along with it's associated files 
    if [[ $file =~ $regexArchivesOnly ]];
    then
      echo "Processing archive file: $file";

      newName=$(echo "${file}" | sed -r "s/${timestampRegex}/$TIMESTAMP/")

      if [ "${file}" != "${newName}" ]; then
        # Rename archive and its associated files with new timestamp
        echo "Renaming ${file} to ${newName}"
        if [ -f "${file}" ]; then
          mv "${file}" "${newName}"
        fi
        if [ -f "${file}.sha256.txt" ]; then
          mv "${file}.sha256.txt" "${newName}.sha256.txt"
        fi
        if [ -f "${file}.json" ]; then
          mv "${file}.json" "${newName}.json"
        fi
        if [ -f "${file}.sig" ]; then
          mv "${file}.sig" "${newName}.sig"
        fi
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
      FILE_EXTENSION=${BASH_REMATCH[7]};

      echo "version:${FILE_VERSION} type: ${FILE_TYPE} arch:${FILE_ARCH} os:${FILE_OS} variant:${FILE_VARIANT} timestamp or version:${FILE_TS_OR_VERSION} timestamp:${TIMESTAMP} extension:${FILE_EXTENSION}";
    fi
  done

  # Rename any remaining non-archive file timestamps that have not already been renamed
  for file in OpenJDK*
  do
    if [[ ! $file =~ $regexArchivesOnly && $file != *"makefailurelogs"* ]];
    then
      echo "Processing non-archive file: $file";

      # Check no new file type archive has been added without updating regexArchivesOnly
      if [[ $file == *.tar.gz ]] || [[ $file == *.zip ]] || [[ $file == *.pkg ]] || [[ $file == *.msi ]]; then
        echo "ERROR: ${file} is an archive but does not match regex ${regexArchivesOnly}, please update sbin/Release.sh"
        exit 1
      fi

      if [[ $file =~ $timestampRegex ]]; then
        newName=$(echo "${file}" | sed -r "s/${timestampRegex}/$TIMESTAMP/")

        if [ "${file}" != "${newName}" ]; then
          # Rename non-archive file with new timestamp
          echo "Renaming ${file} to ${newName}"
          mv "${file}" "${newName}"
        fi
      fi
    fi
  done
  # Grab the list of files to upload
  # NOTE: If adding something here you may need to change the EXPECTED values in releaseCheck.sh
  files=$(find $PWD \( -name "OpenJDK*.tar.gz" -o -name "OpenJDK*.sha256.txt" -o -name "OpenJDK*.zip" -o -name "OpenJDK*.pkg" -o -name "OpenJDK*.msi" -o -name "OpenJDK*.json" -o -name "OpenJDK*.sig" \) | grep -v "makefailurelogs" | tr '\n' ' ')
else 
  #TODO: enhance to a general file name - update groovy release() - case ~/.*AQAvitTapFiles.*/: "adopt"; break;
  files=$(ls "$PWD"/AQAvitTapFiles.tar.gz)
fi

echo ""
echo "RELEASE flag is set to: $RELEASE"
echo ""

RELEASE_OPTION=""
if [ "$RELEASE" == "true" ]; then
  description="Official Release of $TAG"
  RELEASE_OPTION="--release"
elif [ "$UPLOAD_TESTRESULTS_ONLY" == "true" ]; then
  echo "Test results are only needed to upload for releases!"
  exit 1
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
    # Run releaseCheck.sh to check that the correct number of artifacts are live
    if [ -z "$TIMESTAMP" -a "$UPLOAD_TESTRESULTS_ONLY" = "false" ]; then
      echo "*** PERFORMING RELEASE CHECK TO SEE IF THERE ARE ANY UNEXPECTED PROBLEMS ***"
      ../sbin/releaseCheck.sh ${VERSION#JDK} $TAG VERBOSE
    fi
fi
