#!/bin/bash
HOTFIX=$1

git checkout master
git pull origin --prune
opened_branches=$(git branch -r | grep hotfix)
if [ ! -z "$opened_branches" ]; then
    echo "============= ERROR ================="
    echo "There are remote hotfixes already opened"
    echo "Consider closing them"
    echo "Exiting with error"
    echo $opened_branches
    exit 1
fi

git checkout -b "hotfix/$HOTFIX" master
mvn versions:set -DnewVersion=$HOTFIX-SNAPSHOT
mvn versions:commit
git commit -am "Hotfix version number updated"
git push origin hotfix/$HOTFIX

echo "Do the fix on branch hotfix/"$HOTFIX

echo
echo "Done"
