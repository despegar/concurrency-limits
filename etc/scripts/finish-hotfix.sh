#!/bin/bash

# Get release candidate branch name. Assume there is only one
RELEASE_BRANCH_NAME=$(git branch -r | grep "origin/hotfix" | awk '{ sub(/origin\/hotfix\//,""); print }')

if [ -z $RELEASE_BRANCH_NAME ]; then 
    echo "No hotfix candidate branch found"; 
    exit 1;
fi

# Trim trailing spaces
RELEASE_VERSION=$(sed -e 's/^[[:space:]]*//' <<<"$RELEASE_BRANCH_NAME")
RELEASE_BRANCH_NAME=hotfix/$RELEASE_VERSION
echo $RELEASE_BRANCH_NAME

#Sanity pulls
git checkout master
git pull origin master
git checkout $RELEASE_BRANCH_NAME
git pull origin $RELEASE_BRANCH_NAME

git checkout master
git merge -s recursive -X theirs $RELEASE_BRANCH_NAME
git push origin master

git checkout develop
git pull origin develop
git merge --no-ff -s recursive -X ours $RELEASE_BRANCH_NAME
git push origin develop

git checkout master
git pull origin master
mvn -B -e release:prepare -PRELEASE
mvn -B -e release:perform -PRELEASE

# Revert poms from git to leave right version numbers
git revert HEAD -n
git commit -m "keep non-snapshot versions for $RELEASE_BRANCH_NAME"
git push origin master

git branch -D $RELEASE_BRANCH_NAME
git push origin :$RELEASE_BRANCH_NAME

mvn clean
