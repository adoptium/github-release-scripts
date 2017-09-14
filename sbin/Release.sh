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

TIMESTAMP="$(date +'%Y%d%m')"
npm install
for f in OpenJDK*.tar.gz
do
  case $f in
    *Linux*)
      OS=Linux && EXT=tar.gz
      case $f in
        *x64*)
        ARCH=x64 ;;
        *s390x*)
        ARCH=s390x ;;
        *ppc64le*)
        ARCH=ppc64le ;;
        *aarch64*)
        ARCH=aarch64 ;;
    esac ;;
    *Mac*)
    OS=Mac && ARCH=x64 && EXT=tar.gz ;;
    *AIX*)
    OS=AIX && ARCH=ppc64 && EXT=tar.gz ;;
  esac
  if [ "$REPO" == "releases" ]; then
    mv $f Open${VERSION}_${ARCH}_${OS}_${TAG}.${EXT}
    elif [ "$REPO" == "nightly" ]; then
    mv $f Open${VERSION}_${ARCH}_${OS}_$TIMESTAMP.${EXT}
  fi
done
for f in OpenJDK*.zip
do
  case $f in
    *Win*)
    OS=Win && ARCH=x64 && EXT=zip ;;
  esac
  if [ "$REPO" == "releases" ]; then
    mv $f Open${VERSION}_${ARCH}_${OS}_${TAG}.${EXT}
    elif [ "$REPO" == "nightly" ]; then
    mv $f Open${VERSION}_${ARCH}_${OS}_$TIMESTAMP.${EXT}
  fi
done
for c in OpenJDK*.sha256.txt
do
  case $c in
    *Linux*)
      OS=Linux
      EXT=tar.gz
      case $c in
        *x64*)
        ARCH=x64 ;;
        *s390x*)
        ARCH=s390x ;;
        *ppc64le*)
        ARCH=ppc64le ;;
        *aarch64*)
        ARCH=aarch64 ;;
    esac ;;
    *Win*)
    OS=Win && ARCH=x64 && EXT=zip ;;
    *Mac*)
    OS=Mac && ARCH=x64 && EXT=tar.gz ;;
    *AIX*)
    OS=AIX && ARCH=ppc64 && EXT=tar.gz ;;
  esac
  FILENAME=`cat $c | awk  '{print $2}'`
  if [ "$REPO" == "releases" ]; then
    sed -i -e "s/${FILENAME}/Open${VERSION}_${ARCH}_${OS}_${TAG}.${EXT}/g" $c
    mv $c Open${VERSION}_${ARCH}_${OS}_${TAG}.sha256.txt

    elif [ "$REPO" == "nightly" ]; then
    sed -i -e "s/${FILENAME}/Open${VERSION}_${ARCH}_${OS}_$TIMESTAMP.${EXT}/g" $c
    mv $c Open${VERSION}_${ARCH}_${OS}_$TIMESTAMP.sha256.txt
  fi
done
files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt,.zip} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
if [ "$REPO" == "releases" ]; then
  node upload.js --files $files --tag ${TAG} --description "Official Release of $TAG" --repo $REPO
  elif [ "$REPO" == "nightly" ]; then
  node upload.js --files $files --tag ${TAG}-${TIMESTAMP} --description "Nightly Build of $TAG" --repo $REPO
fi
export VERSION=`echo $VERSION | awk '{print tolower($0)}'`
node app.js
./sbin/gitUpdate.sh
