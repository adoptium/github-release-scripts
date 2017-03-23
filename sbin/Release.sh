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
mv $f OpenJDK8_${ARCH}_${OS}_$TIMESTAMP.${EXT}
done
files=`ls $PWD/OpenJDK*.tar.gz | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g'`
node upload.js --files $files --tag ${VERSION}-${TIMESTAMP} --version $VERSION --repo $REPO
node app.js
./sbin/gitUpdate.sh
