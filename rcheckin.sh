#!/bin/sh
 
check_err()
{
    # parameter 1 is last exit code
    # parameter 2 is error message that should be shown if error code is not 0
    if [ "${1}" -ne "0" ]; then
        cat '~temp.log'
        echo ${2}
        rm -f '~temp.log' > /dev/null
        exit ${1}
    fi;
    rm -f '~temp.log' > /dev/null
}
 
if [ ! -z "$(git status --porcelain)" ]; then
    echo "Your status is not clean, can't continue"
    exit 1;
fi;
 
echo "Fetching origin..."
git fetch origin
 
if [ -n "`git rev-list HEAD..origin/master`" ]; then
    echo "origin/master has some TFS checkins that are conflicting with your branch. Please reabse first, then try to rcheckin again"
    exit 1;
fi;
 
echo "Marking latest TFS commit with bootstrap..."
git tfs bootstrap -d
 
git tfs rcheckin
check_err $? "rcheckin exited with error"
 
git push origin HEAD:master
check_err $? "Can't push HEAD to origin"