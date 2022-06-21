#!/bin/sh
# simple script to check the number of artifacts that have been uploaded for a particular release
# It can help the releaser know what is still outstanding.
# It checks the number of artifacts in the temurin-XX binaries repository for each platform
# Requires curl but nothing much else

[ $# -lt 2 ] && echo "Usage: releaseCheck version tag [verbose]" && exit 1
TEMURIN_VERSION=$1
TEMURIN_TAG=$2
VERBOSE=$3

echo Grabbing information from https://github.com/adoptium/temurin${TEMURIN_VERSION}-binaries/releases/tag/${TEMURIN_TAG}
curl -q https://github.com/adoptium/temurin${TEMURIN_VERSION}-binaries/releases/tag/${TEMURIN_TAG} > releaseCheck.$$.tmp || exit 1

#### LINUX (ALL)
for ARCH in x64 aarch64 ppc64le s390x arm; do
  # jre, jdk, debugimage, static-libs (Except JDK8) in base, json, sha256
  EXPECTED=16; [ "${TEMURIN_VERSION}" -eq 8 ] && EXPECTED=12
  if ! [ "${TEMURIN_VERSION}" -eq 8 -a "$ARCH" = "s390x" ]; then
    if [ $(cat releaseCheck.$$.tmp | grep ${ARCH}_linux | grep href | cut -d'"' -f2 | wc -l) -eq $EXPECTED ]
    then
       echo "Linux on $ARCH: OK!"
    else
      echo "Linux on $ARCH: Not complete:"
      [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep ${ARCH}_linux | grep href | cut -d'"' -f2
    fi
  fi
done

### AIX - Same number of artifacts as Linux so don't adjust EXPECTED
for ARCH in ppc64; do
  if [ $(cat releaseCheck.$$.tmp | grep ${ARCH}_aix | grep href | cut -d'"' -f2 | wc -l) -eq $EXPECTED ]
  then
     echo "AIX on $ARCH: OK!"
  else
     echo "AIX on $ARCH: Not complete:"
     [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep ${ARCH}_aix | grep href | cut -d'"' -f2
  fi
done

### Alpine - Same number of artifacts as Linux so don't adjust EXPECTED
for ARCH in x64; do
  if [ $(cat releaseCheck.$$.tmp | grep ${ARCH}_alpine | grep href | cut -d'"' -f2 | wc -l) -eq $EXPECTED ]
  then
     echo "Alpine on $ARCH: OK!"
  else
     echo "Alpine on $ARCH: Not complete:"
     [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep ${ARCH}_alpine | grep href | cut -d'"' -f2
  fi
done
 
### Solaris - Same number of artifacts as Linux so don't adjust EXPECTED
if [ "${TEMURIN_VERSION}" -eq 8 ]; then
  for ARCH in x64 sparcv9; do
    if [ $(cat releaseCheck.$$.tmp | grep ${ARCH}_solaris | grep href | cut -d'"' -f2 | wc -l) -eq $EXPECTED ]
    then
      echo "Solaris on $ARCH: OK!"
    else
      echo "Solaris on $ARCH: Not complete:"
      [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep ${ARCH}_solaris | grep href | cut -d'"' -f2
    fi
  done
fi

#### WINDOWS
for ARCH in x64 x86-32; do
  # jre, jdk, jre-msi, jdk-msi, debugimage, static-libs (Except JDK8) in base, json, sha256
  EXPECTED=24; [ "${TEMURIN_VERSION}" -eq 8 ] && EXPECTED=20
  if [ $(cat releaseCheck.$$.tmp | grep ${ARCH}_windows | grep href | cut -d'"' -f2 | wc -l) -eq $EXPECTED ]
  then
     echo "Windows on $ARCH: OK!"
  else
     echo "Windows on $ARCH: Not complete:"
     [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep ${ARCH}_windows | grep href | cut -d'"' -f2
  fi
done

### MAC
for ARCH in x64 aarch64; do
  # jre, jdk, jre-pkg, jdk-pkg, debugimage, static-libs (Except JDK8) in base, json, sha256
  EXPECTED=24; [ "${TEMURIN_VERSION}" -eq 8 ] && EXPECTED=20
  if ! [ "${TEMURIN_VERSION}" -eq 8 -a "$ARCH" = "aarch64" ]; then
    if [ $(cat releaseCheck.$$.tmp | grep ${ARCH}_mac | grep href | cut -d'"' -f2 | wc -l) -eq $EXPECTED ]
    then
      echo "MacOS on $ARCH: OK!"
    else
      echo "MacOS on $ARCH: Not complete:"
      [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep ${ARCH}_mac | grep href | cut -d'"' -f2
    fi
  fi
done

if [ $(cat releaseCheck.$$.tmp | grep sources | grep href | cut -d'"' -f2 | wc -l) -eq 3 ]
then
   echo "Source images: OK!"
else
   echo "Source images: Not complete:"
   [ ! -z "$VERBOSE" ] && cat releaseCheck.$$.tmp | grep sources | grep href | cut -d'"' -f2
fi

rm releaseCheck.$$.tmp
