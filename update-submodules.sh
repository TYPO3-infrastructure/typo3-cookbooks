#!/bin/bash

export LANG=C

# Check if the repository is clean.
# If this is the case, changes will be committed automatically.
REPOSITORY_IS_DIRTY_AT_START=0
if [ $(git status --short | wc -l) != 0 ]; then
	REPOSITORY_IS_DIRTY_AT_START=1
fi

# Check if the last commit was a submodule update and if it was not pushed yet.
# If this is the case, the last commit is amended at the end of the run.
LAST_UPDATE_IS_PUSHED=1
if [ $(git log --oneline origin/master..master | wc -l) != 0 ]; then
	LAST_UPDATE_IS_PUSHED=0
fi

LAST_COMMIT_IS_SUBMODULE_UPDATE=0
if git log --oneline -n 1 HEAD | egrep -q "Update submodules$"; then
	LAST_COMMIT_IS_SUBMODULE_UPDATE=1
fi

git submodule foreach git pull

echo
echo "==========================================="

if [ $(git status --short | wc -l) = 0 ]; then
	echo "DONE - No changes."
	exit 0
fi

if [ $REPOSITORY_IS_DIRTY_AT_START = 0 ]; then
	echo "DONE - Committing changes..."
	git add .

	# Amend the last commit if it was not pushed yet
	if [ $LAST_UPDATE_IS_PUSHED = 0 ] && [ $LAST_COMMIT_IS_SUBMODULE_UPDATE = 1 ]; then
		git commit --amend -m "Update submodules"
	else
		git commit -m "Update submodules"
	fi
else
	echo "DONE"
	echo
	echo "Repository was not clean at start, please check changes and commit manually:"
	echo
	echo "\$ git add ."
	echo "\$ git commit -m \"Update submodules\""
fi

exit 0
