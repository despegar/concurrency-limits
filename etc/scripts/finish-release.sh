#!/bin/bash

# Get release candidate branch name. Assume there is only one
RELEASE_BRANCH_NAME=$(git branch -r | grep "origin/release" | awk '{ sub(/origin\/release\//,""); print }')

if [ -z $RELEASE_BRANCH_NAME ]; then 
    echo "No release candidate branch found"; 
    exit 1;
fi

# Trim trailing spaces
RELEASE_BRANCH_NAME=$(sed -e 's/^[[:space:]]*//' <<<"$RELEASE_BRANCH_NAME")

# Close the branch. Merge to develop and master (don't take off the hyphens!!)

git checkout master
git pull origin master
git checkout release/$RELEASE_BRANCH_NAME
git pull origin release/$RELEASE_BRANCH_NAME
git checkout master
git merge -s recursive -X theirs release/$RELEASE_BRANCH_NAME
git push origin master
git checkout develop
git pull origin develop
git merge --no-ff release/$RELEASE_BRANCH_NAME
git push origin develop

git checkout master
git pull origin master
mvn  -B -e release:prepare -PRELEASE
mvn  -B -e release:perform -PRELEASE
git pull origin master

# Revert poms from git to leave right version numbers
git revert HEAD -n
git commit -m "keep non-snapshot versions for $RELEASE_BRANCH_NAME"
git push origin master

git branch -D release/$RELEASE_BRANCH_NAME
git push origin :release/$RELEASE_BRANCH_NAME

mvn clean
