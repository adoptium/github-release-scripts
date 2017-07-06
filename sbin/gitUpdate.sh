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

if [ "$REPO" == "releases" ]; then
  git clone git@github.com:AdoptOpenJDK/openjdk-releases.git
  rm -rf openjdk-releases/release.json
  mv releases.json openjdk-releases/
  mv latest_release.json openjdk-releases/
  cd $WORKSPACE/openjdk-releases
  git add releases.json latest_release.json
  git commit -m "updated releases.json" || echo "nothing to commit"
  if [ `git diff origin/master | wc -l` > 0 ]; then
    git push
  else
    echo "releases already up to date"
  fi
fi

if [ "$REPO" == "nightly" ]; then
  git clone git@github.com:AdoptOpenJDK/openjdk-nightly.git
  rm -rf openjdk-nightly/nightly.json
  mv nightly.json openjdk-nightly/
  mv latest_nightly.json openjdk-nightly/
  cd $WORKSPACE/openjdk-nightly
  git add nightly.json latest_nightly.json
  git commit -m "updated nightly.json" || echo "nothing to commit"
  if [ `git diff origin/master | wc -l` > 0 ]; then
    git push
  else
    echo "nightly already up to date"
  fi
fi
