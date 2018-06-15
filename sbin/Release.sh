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
# Expect a naming convention for build artifacts to follow this pattern:
# OpenJDK<version>_<arch>_<os>_<timestampOrTag>.<extension>
# Examples: OpenJDK8_x64_Windows_201813060547.zip, 
#           OpenJDK8_x64_LinuxLH_201813060547.tar.gz, 
#           OpenJDK10_aarch64_Linux_201813060547.tar.gz.sha256.txt
#           OpenJDKamber_x64_Linux_201813061304.tar.gz	
for file in OpenJDK*
do
#              1)VERSION 2)ARCH         3)OS           4)TS_TAG       5)EXTENSION 
  regex="Open(JDK[a-zA-Z0-9]+)_([a-zA-Z0-9]+)_([a-zA-Z0-9]+)_([a-zA-Z0-9]+).(tar.gz|zip)(.sha256.txt)?";
  echo "Processing $file";
  if [[ $file =~ $regex ]]; 
  then 
    VERSION=${BASH_REMATCH[1]};
    ARCH=${BASH_REMATCH[2]};
    OS=${BASH_REMATCH[3]};
    TS_TAG=${BASH_REMATCH[4]};
    EXTENSION=${BASH_REMATCH[5]};
    SHA_EXT=${BASH_REMATCH[6]};
    echo "version:${VERSION} arch: ${ARCH} os:${OS} timestampOrTag:${TS_TAG} extension: ${EXTENSION} sha_ext: ${SHA_EXT}"; 
  fi
  if [ "$EXTENSION" == "zip" ]; 
  then
    FILENAME=`cat $file | awk  '{print $2}'`
    sed -i -e "s/${FILENAME}/Open${VERSION}_${ARCH}_${OS}_${TS_TAG}.${EXTENSION}/g" $file
  fi
  if [ "$SHA_EXT" == ".sha256.txt" ]; 
  then
    mv $file "Open${VERSION}_${ARCH}_${OS}_${TS_TAG}${SHA_EXT}
  else
    mv $file "Open${VERSION}_${ARCH}_${OS}_${TS_TAG}.${EXTENSION}"
  fi
done

files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt,.zip} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
if [ "$REPO" == "releases" ]; then
  node upload.js --files $files --tag ${TS_TAG} --description "Official Release of $TAG" --repo $REPO
  elif [ "$REPO" == "nightly" ]; then
  node upload.js --files $files --tag ${TAG}-${TS_TAG} --description "Nightly Build of $TAG" --repo $REPO
fi
node app.js
./sbin/gitUpdate.sh
