#!/bin/bash

function get_current_version () {
    # run mvn command first for plugin download (if it does not exist in current host)
    local d=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }'`
    local v=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }'`
    echo $v
}

function get_prev_dev_version () {
	local v=$1
	# Get the last number. First remove any suffixes (such as '-SNAPSHOT').
	local cleaned=`echo $v | sed -e 's/[^0-9][^0-9]*$//'`
	local last_num=`echo $cleaned | sed -e 's/[0-9]*\.//g'`
	local prev_num=$(($last_num-1))
	# Finally replace the last number in version string with the new one.
	local stripped=`echo $v | sed -e 's/[0-9][0-9]*\([^0-9]*\)$/'"$prev_num"'/'`
	v=$stripped
	echo $v
}

git checkout develop
git pull origin develop

CURRENT_VERSION=$(get_current_version)
PREV_VERSION=$(get_prev_dev_version $CURRENT_VERSION)
PREV_DEV_VERSION=$PREV_VERSION"-SNAPSHOT"

echo
echo "Current version : "$CURRENT_VERSION
echo "Prev version : "$PREV_VERSION
echo "Prev Dev version: "$PREV_DEV_VERSION
echo 

echo "syncing local branches with remote origin"
git remote prune origin
release=$(git branch -r | grep release)
if [ ! -z $release ]; then
	echo "There is an existing remote release branch ($release). Removing it."
	git push origin :release/$PREV_VERSION

	echo "Erasing local release branches"
	local_release=$(git branch | grep release)
	git branch -D $local_release > /dev/null

	#Going back version numbers
	mvn --batch-mode release:update-versions -DdevelopmentVersion=$PREV_DEV_VERSION
	git add .
	git commit -m "Release $CURRENT_VERSION canceled. Went back to $PREV_DEV_VERSION"
	git push origin develop
else
	echo "There is no release started. Release branch not found."
	exit 2;
fi 
