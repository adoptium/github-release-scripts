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
for file in OpenJDK*
do

  timestampRegex="[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{2}"
  regex="OpenJDK([[:alnum:]]+)_([[:alnum:]]+)_([[:alnum:]]+)_([[:alnum:]]+)_($timestampRegex).(tar.gz|zip)(.sha256.txt)?";

  echo "Processing $file";
  if [[ $file =~ $regex ]];
  then
    VERSION=${BASH_REMATCH[1]};
    ARCH=${BASH_REMATCH[2]};
    OS=${BASH_REMATCH[3]};
    VARIANT=${BASH_REMATCH[4]};
    TS_TAG=${BASH_REMATCH[5]};
    EXTENSION=${BASH_REMATCH[6]};
    SHA_EXT=${BASH_REMATCH[7]};
    echo "version:${VERSION} arch:${ARCH} os:${OS} variant:${VARIANT} timestampOrTag:${TS_TAG} extension:${EXTENSION} sha_ext:${SHA_EXT}";
  fi
done

files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt,.zip} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
if [ "$REPO" == "releases" ]; then
  node upload.js --files $files --tag ${TS_TAG} --description "Official Release of $TAG" --repo $REPO
  elif [ "$REPO" == "nightly" ]; then
  node upload.js --files $files --tag ${TAG}-${TS_TAG} --description "Nightly Build of $TAG" --repo $REPO
fi
#node app.js
#./sbin/gitUpdate.sh
