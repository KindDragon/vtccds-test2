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
 
echo "$(date) checkout master branch"
git checkout master
 
echo "$(date) Pulling from TFS..."
git tfs pull -d > '~temp.log'
check_err $? "Pulling from TFS resulted in error";
 
echo "$(date) Checkout staging 'git_tfs_foo' branch..."
git checkout git_tfs_foo
echo "$(date) End Process!"

