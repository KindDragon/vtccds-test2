#script to create a branch in git-tfs
if [ $# -ne 3 ] ; then
  echo "parameters : ServerUrl Repository localBranch"
  echo 'ex : "http://myTfsServer:8080/tfs/Repository" "$/MyProject/MyTFSBranch" "myBranch"'
  exit -1
fi

#find TFS first commit of the branch
let first_commit=`tf history $2 | grep "^[0-9]" | awk '{print $1}'`
#Take the parent to have the root commit
let root_commit=$((first_commit-1))
echo "TFS root commit:$root_commit"

#find the sha of the root parent in git log
myCommand="git log --pretty=format:%H --grep=';C$root_commit' > git_tfs_sha.txt"
eval $myCommand
sha1_root_commit=$(<git_tfs_sha.txt)
echo "Git root commit:$sha1_root_commit"
if [ -z $sha1_root_commit ] ; then
  echo "Error during detecting commit root :("
  rm git_tfs_sha.txt
  exit -1
fi
#create a local branch on this commit
git checkout -b $3 $sha1_root_commit

#modify the config file to add the tfs remote
cp -a ./.git/config ./.git/config_git_tfs_new_branch.old
echo "
[tfs-remote \"$3\"]
	url = $1
	repository = $2
	fetch = refs/remotes/default/$3" >> ./.git/config

#create the remote file to join the commit to the trunk
echo $sha1_root_commit > ./.git/refs/remotes/tfs/$3
#git rev-parse $3 >> ./.git/refs/remotes/tfs/$3

#fetch commits
echo "Fetching tfs commits..."
git tfs fetch -i $3
#reset the local branch to the head of the 
git reset --soft tfs/$3
rm git_tfs_sha.txt
