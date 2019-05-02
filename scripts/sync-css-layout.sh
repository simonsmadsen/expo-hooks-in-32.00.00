#!/usr/bin/env bash

function usage {
  echo "usage: sync-css-layout.sh <pathToGithubRepo> <pathToFbSourceRepo>";
}

function patchfile {
  # Add React Native copyright
  printf "/**\n"  > /tmp/yogasync.tmp
  printf " * Copyright (c) 2014-present, Facebook, Inc.\n"  >> /tmp/yogasync.tmp
  printf " *\n" >> /tmp/yogasync.tmp
  printf " * This source code is licensed under the MIT license found in the\n"  >> /tmp/yogasync.tmp
  printf " * LICENSE file in the root directory of this source tree.\n"  >> /tmp/yogasync.tmp
  printf " */\n\n"  >> /tmp/yogasync.tmp
  printf "// NOTE: this file is auto-copied from https://github.com/facebook/css-layout\n" >> /tmp/yogasync.tmp
  # The following is split over four lines so Phabricator doesn't think this file is generated
  printf "// @g" >> /tmp/yogasync.tmp
  printf "enerated <<S" >> /tmp/yogasync.tmp
  printf "ignedSource::*O*zOeWoEQle#+L" >> /tmp/yogasync.tmp
  printf "!plEphiEmie@IsG>>\n\n" >> /tmp/yogasync.tmp
  tail -n +9 $1 >> /tmp/yogasync.tmp
  mv /tmp/yogasync.tmp $1
  $ROOT/fbandroid/scripts/signedsource.py sign $1
}

if [ -z $1 ]; then
  usage
  exit 1
fi

if [ -z $2 ]; then
  usage
  exit 1
fi

GITHUB=$1
ROOT=$2

set -e # exit if any command fails

echo "Making github project..."
pushd $GITHUB
COMMIT_ID=$(git rev-parse HEAD)
popd

C_SRC=$GITHUB/src/
JAVA_SRC=$GITHUB/src/java/src/com/facebook/yoga
TESTS=$GITHUB/src/java/tests/com/facebook/yoga
FBA_SRC=$ROOT/xplat/js/react-native-github/ReactAndroid/src/main/java/com/facebook/yoga/
FBA_TESTS=$ROOT/fbandroid/javatests/com/facebook/yoga/
FBO_SRC=$ROOT/xplat/js/react-native-github/React/Layout/

echo "Copying fbandroid src files over..."
cp $JAVA_SRC/*.java $FBA_SRC
echo "Copying fbandroid test files over..."
cp $TESTS/*.java $FBA_TESTS
echo "Copying fbobjc src files over..."
cp $C_SRC/Layout.{c,h} $FBO_SRC

echo "Patching files..."
for sourcefile in $FBA_SRC/*.java; do
  patchfile $sourcefile
done
for testfile in $FBA_TESTS/*.java; do
  patchfile $testfile
done
for sourcefile in $FBO_SRC/Layout.{c,h}; do
  patchfile $sourcefile
done

echo "Writing README"

echo "The source of truth for css-layout is: https://github.com/facebook/css-layout

The code here should be kept in sync with GitHub.
HEAD at the time this code was synced: https://github.com/facebook/css-layout/commit/$COMMIT_ID

There is generated code in:
 - README (this file)
 - fbandroid/java/com/facebook/yoga
 - fbandroid/javatests/com/facebook/yoga
 - xplat/js/react-native-github/React/Layout

The code was generated by running 'make' in the css-layout folder and running:

  scripts/sync-css-layout.sh <pathToGithubRepo> <pathToFbSourceRepo>
" > /tmp/yogasync.tmp

cp /tmp/yogasync.tmp "$FBA_SRC/README"
cp /tmp/yogasync.tmp "$FBO_SRC/README"
