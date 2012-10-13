#script to create a branch in git-tfs
if [ $# -ne 3 ] ; then
  echo "parameters : $/ProjectRepository/BranchDirectory localBranchName $/ProjectRepository/SourceBranchDirectory"
  echo 'ex : "$/MyProject/MyTFSBranch" "myBranch" "$/MyProject/MyTFSTrunk"' 
  echo "parameters : $/ProjectRepository/BranchDirectory localBranchName IdParentCommitBeforeBranching"
  echo 'ex : "$/MyProject/MyTFSBranch" "myBranch" 345' 
  exit -1
fi

if [ ! -z "$(echo $2 | sed -n 's/\([.\/]\)/\1/p')" ]; then
	echo 'The local branch name contains forbiden characters : . / \ '
	exit -1
fi

#find TFS first commit of the branch
if [[ $3 != *[!0-9]* ]]; then
	let root_commit=$3
	echo "TFS root commit:$root_commit"
  else
	let root_commit=`tf history $1 | grep "^[0-9]" | awk '{print $1}'`
	if [ -z $root_commit ] ; then
		echo "Error executing commant 'tf' :( Remember that the script must be run from a TFS mapped directory ! (Thank you TFS!)"
		exit -1
	fi
	echo $root_commit
	#Take the parent to have the root commit
	while [ $root_commit -ne 0 ] && [ -z $sha1_root_commit ] ; do
		root_commit=$((root_commit-1))
		#echo "try to find if changeset $root_commit is the good one" 
		sha1_root_commit=$(git log --pretty=format:%H --grep="$3;C$root_commit[^0-9]")
		#echo "Is Git sha root commit:$sha1_root_commit"
	done
	if [ $root_commit -eq 0 ] ; then
		echo "The root changset not founded!"
		exit -1
	fi
	echo "The root changset founded id is $root_commit !"
	echo "Please verify that it's the good changset in the TFS history before calling the script with the parameters:"
	echo "$1 $2 $root_commit"
	exit 0
fi

url_server=`git config --local --get tfs-remote.default.url`
if [ -z $url_server ] ; then
  echo "Error : No tfs/default detected. This repository is not in the good state!"
  exit -1
fi

#find the sha of the root parent in git log
sha1_root_commit=$(git log --pretty=format:%H --grep=";C$root_commit[^0-9]")
echo "Git root commit:$sha1_root_commit"

if [ -z $sha1_root_commit ] ; then
  echo "Error during detecting commit root :("
  exit -1
fi

git stash save

#create a local branch on this commit
git checkout -b $2 $sha1_root_commit

#modify the config file to add the tfs remote
cp -a ./.git/config ./.git/config_git_tfs_new_branch.old
echo "
[tfs-remote \"$2\"]
	url = $url_server
	repository = $1
	fetch = refs/remotes/tfs/$2" >> ./.git/config

#create the remote file to join the commit to the trunk
echo $sha1_root_commit > ./.git/refs/remotes/tfs/$2
#git rev-parse $2 >> ./.git/refs/remotes/tfs/$2

#fetch commits
echo "Fetching tfs commits..."
git tfs fetch -i $2
#reset the local branch to the head of the branch
git reset --hard tfs/$2

