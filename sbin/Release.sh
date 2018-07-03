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

npm install

timestampRegex="[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}"
regex="OpenJDK([[:digit:]]+)U?_([[:alnum:]]+)_([[:alnum:]]+)_([[:alnum:]]+)_($timestampRegex).(tar.gz|zip)";
regexArchivesOnly="${regex}$";
regexAllFiles="${regex}(.sha256.txt)?";

TIMESTAMP="$(date -u +'%Y-%m-%d-%H-%M')"

# Rename to ensure a consistent timestamp across release
for file in OpenJDK*
do
  echo "Processing $file";

  if [[ $file =~ $regexArchivesOnly ]];
  then
    newName=$(echo "${file}" | sed -r "s/${timestampRegex}/$TIMESTAMP/")

    # Rename archive and checksum file with now timestamp
    mv "${file}" "${newName}"
    mv "${file}.sha256.txt" "${newName}.sha256.txt"

    # Fix checksum file name
    sed -i -r "s/^([0-9a-fA-F ]+).*/\1${newName}/g" "${newName}.sha256.txt"

    FILE_VERSION=${BASH_REMATCH[1]};
    FILE_ARCH=${BASH_REMATCH[2]};
    FILE_OS=${BASH_REMATCH[3]};
    FILE_VARIANT=${BASH_REMATCH[4]};
    FILE_EXTENSION=${BASH_REMATCH[6]};
    FILE_SHA_EXT=${BASH_REMATCH[7]};

    echo "version:${FILE_VERSION} arch:${FILE_ARCH} os:${FILE_OS} variant:${FILE_VARIANT} timestamp:${TIMESTAMP} extension:${FILE_EXTENSION} sha_ext:${FILE_SHA_EXT}";
  fi
done

files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt,.zip} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
if [ "$REPO" == "releases" ]; then
  node upload.js --files $files --tag ${TIMESTAMP} --description "Official Release of $TAG" --repo $REPO
elif [ "$REPO" == "nightly" ]; then
  node upload.js --files $files --tag ${TAG}-${TIMESTAMP} --description "Nightly Build of $TAG" --repo $REPO
fi

# TODO: Bring back when ready to release
#node app.js
#./sbin/gitUpdate.sh
