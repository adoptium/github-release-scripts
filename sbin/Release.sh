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

# Sanity checks ...
if [ ! "${REPO}" == "nightly" -a ! "${REPO}" == "releases" ]; then
   echo REPO environment variable should be set to nightly or releases - aborting
   exit 1
fi
if [ "${REPO}" == "releases" -a -z "$TAG" ]; then
  echo Release build requested, but no TAG variable in the environment
  exit 1
fi
if [ -z "${VERSION}" ]; then
  echo 'VERSION not specified - should be JDKn[-VARIANT] e.g. JDK8 or JDK11-OPENJ9'
  exit 1
fi

npm install
# Expect a naming convention for build artifacts to follow this pattern:
# OpenJDK<version>_<arch>_<os>_<timestampOrTag>.<extension>
# Examples: OpenJDK8_x64_Windows_201813060547.zip, 
#           OpenJDK8_x64_LinuxLH_201813060547.tar.gz, 
#           OpenJDK10_aarch64_Linux_201813060547.tar.gz.sha256.txt,
#           OpenJDKamber_x64_Linux_201813061304.tar.gz	
for file in OpenJDK*
do
#                            1)ARCH         2)OS           3)TS_OR_TAG    4)EXTENSION 5) SHA_EXT 
  regex="OpenJDK[a-zA-Z0-9]+_([a-zA-Z0-9]+)_([a-zA-Z0-9]+)_([a-zA-Z0-9]+).(tar.gz|zip)(.sha256.txt)?";
  echo "Processing $file";
  if [[ $file =~ $regex ]]; 
  then 
    ARCH=${BASH_REMATCH[1]};
    OS=${BASH_REMATCH[2]};
    TS_OR_TAG=${BASH_REMATCH[3]};
    EXTENSION=${BASH_REMATCH[4]};
    SHA_EXT=${BASH_REMATCH[5]};
    echo "version:${VERSION} arch:${ARCH} os:${OS} timestampOrTag:${TS_OR_TAG} extension:${EXTENSION} sha_ext:${SHA_EXT}"; 
  fi
  if [ "$EXTENSION" == "zip" -a "$SHA_EXT" == ".sha256.txt" ]; 
  then
    FILENAME=`cat $file | awk  '{print $2}'`
    if [ "${REPO}" == "releases" ]; then
      sed -i -e "s/${FILENAME}/Open${VERSION}_${ARCH}_${OS}_${TAG}.${EXTENSION}/g" $file
    else
      sed -i -e "s/${FILENAME}/Open${VERSION}_${ARCH}_${OS}_${TS_OR_TAG}.${EXTENSION}/g" $file
    fi
  fi
  if [ "$SHA_EXT" == ".sha256.txt" ]; 
  then
    if [ "${REPO}" == "releases" ]; then
      mv $file "Open${VERSION}_${ARCH}_${OS}_${TAG}${SHA_EXT}"
    else
      mv $file "Open${VERSION}_${ARCH}_${OS}_${TS_OR_TAG}${SHA_EXT}"
    fi
  else
    if [ "${REPO}" == "releases" ]; then
      mv $file "Open${VERSION}_${ARCH}_${OS}_${TAG}.${EXTENSION}"
    else    
      mv $file "Open${VERSION}_${ARCH}_${OS}_${TS_OR_TAG}.${EXTENSION}"
    fi
  fi
done

files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt,.zip} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
if [ "$REPO" == "releases" ]; then
  node upload.js --files $files --tag ${TAG} --description "Official Release of $TAG" --repo $REPO
  elif [ "$REPO" == "nightly" ]; then
  node upload.js --files $files --tag ${TS_OR_TAG} --description "Nightly Build of $TAG" --repo $REPO
fi
node app.js
./sbin/gitUpdate.sh
