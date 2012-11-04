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
 
echo "$(date) Update launched"
 
if [ ! -z "$(git status --porcelain)" ]; then
    echo "$(date) Your status is not clean, can\'t update"
    exit 1;
fi;
 
echo "$(date) Pulling from central repo first to avoid redundant round-trips to TFS..."
git pull origin master:master > '~temp.log'
check_err $? "Pulling from central repo failed"
 
echo "$(date) Pulling from TFS..."
git tfs pull -d > '~temp.log'
check_err $? "Pulling from TFS resulted in error";
 
local_commits_to_push="$(git rev-list master ^origin/master)"
if [ -z "$local_commits_to_push" ]; then
    echo "$(date) Central repo is up-to-date, nothing to push"
else
    echo "$(date) Pushing updates to central repo"
    git push origin master > '~temp.log'
    check_err $? "Push to central resulted in error";
fi;