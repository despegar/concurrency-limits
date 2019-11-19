#!/bin/bash

function get_current_version () {
    # run mvn command first for plugin download (if it does not exist in current host)
    local d=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }'`
    local v=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }'`
    echo $v
}

function get_next_dev_version () {
    local v=$1
    # Get the last number. First remove any suffixes (such as '-SNAPSHOT').
    local cleaned=`echo $v | sed -e 's/[^0-9][^0-9]*$//'`
    local last_num=`echo $cleaned | sed -e 's/[0-9]*\.//g'`
    local next_num=$(($last_num+1))
    # Finally replace the last number in version string with the new one.
    local stripped=`echo $v | sed -e 's/[0-9][0-9]*\([^0-9]*\)$/'"$next_num"'/'`
    v=$stripped"-SNAPSHOT"
    echo $v
}

CURRENT_VERSION=$(get_current_version)
NEXT_DEV_VERSION=$(get_next_dev_version $CURRENT_VERSION)
RELEASE_VERSION=`echo $CURRENT_VERSION | sed -e 's/[^0-9][^0-9]*$//'`

echo
echo "Current version : "$CURRENT_VERSION
echo "Next Dev version: "$NEXT_DEV_VERSION
echo "Release version : "$RELEASE_VERSION
echo 



echo "Creating branch for release candidate [$RELEASE_VERSION]"
# initialize repo for git flow (with defaults) if not already
git remote prune origin
release=$(git branch -r | grep release)
if [ ! -z $release ]; then
   echo "There is an existing release branch ($release). Finish that one first. Tip: Use cancel-release.sh ;)"
   exit 2;
else
  ##Remove this if it's beign deleted while running finish-release.sh
  echo "Erasing local release branches (just in case ;))"
  local_release=$(git branch | grep release)
  git branch -D $local_release > /dev/null
fi 

git checkout -b master origin/master
git checkout develop

git flow init -d
git checkout develop
git pull
git flow release start $RELEASE_VERSION
git flow release publish $RELEASE_VERSION
echo 

echo "Preparing develop for next version [$NEXT_DEV_VERSION]"
git checkout develop
mvn --batch-mode release:update-versions -DdevelopmentVersion=$NEXT_DEV_VERSION
git add .
git commit -m 'develop prepared for version '"$NEXT_DEV_VERSION"
git push origin develop

echo
echo "Done"

