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
			esac ;;
    *Win*)
    	OS=Win && ARCH=x64 && EXT=zip ;;
    *Mac*)
    	OS=Mac && ARCH=x64 && EXT=tar.gz ;;
  esac
	if [ "$REPO" == "releases" ]; then
		mv $f OpenJDK8_${ARCH}_${OS}_${VERSION}.${EXT}
	elif [ "$REPO" == "nightly" ]; then
		mv $f OpenJDK8_${ARCH}_${OS}_$TIMESTAMP.${EXT}
	fi
done
for c in OpenJDK*.sha256.txt
do
	case $c in
		*Linux*)
			OS=Linux
			case $c in
				*x64*)
					ARCH=x64 ;;
				*s390x*)
					ARCH=s390x ;;
			esac ;;
		*Win*)
			OS=Win && ARCH=x64;;
		*Mac*)
			OS=Mac && ARCH=x64 ;;
	esac
	if [ "$REPO" == "releases" ]; then
		mv $c OpenJDK8_${ARCH}_${OS}_${VERSION}.sha256.txt
	elif [ "$REPO" == "nightly" ]; then
		mv $c OpenJDK8_${ARCH}_${OS}_$TIMESTAMP.sha256.txt
	fi
done
files=`ls $PWD/OpenJDK*{.tar.gz,.sha256.txt} | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
if [ "$REPO" == "releases" ]; then
	node upload.js --files $files --tag ${VERSION} --description "Official Release of $VERSION" --repo $REPO
elif [ "$REPO" == "nightly" ]; then
	node upload.js --files $files --tag ${VERSION}-${TIMESTAMP} --description "Nightly Build of $VERSION" --repo $REPO
fi
node app.js
./sbin/gitUpdate.sh
