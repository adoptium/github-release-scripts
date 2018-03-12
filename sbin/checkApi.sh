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
# loop through openjdk8 repos
export VERSION="jdk8"
node app.js
export REPO="nightly"
./sbin/gitUpdate.sh
export REPO="releases"
./sbin/gitUpdate.sh

# loop through openjdk9 repos
export VERSION="jdk9"
node app.js
export REPO="nightly"
./sbin/gitUpdate.sh
export REPO="releases"
./sbin/gitUpdate.sh

# loop through openjdk10 repos
export VERSION="jdk10"
node app.js
export REPO="nightly"
./sbin/gitUpdate.sh
export REPO="releases"
./sbin/gitUpdate.sh

# loop through openjdk amber repos
export VERSION="amber"
node app.js
export REPO="nightly"
./sbin/gitUpdate.sh

# loop through openjdk8-openj9 repos
export VERSION="jdk8-openj9"
node app.js
export REPO="nightly"
./sbin/gitUpdate.sh
export REPO="releases"
./sbin/gitUpdate.sh

# loop through openjdk9-openj9 repos
export VERSION="jdk9-openj9"
node app.js
export REPO="nightly"
./sbin/gitUpdate.sh
export REPO="releases"
./sbin/gitUpdate.sh
