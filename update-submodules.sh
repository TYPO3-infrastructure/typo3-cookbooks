#!/bin/bash

CONTINUE_FROM=${1%/}

set -eu

export LANG=C

# Check if the repository is clean at start.
# If this is the case, changes will be committed automatically.
REPOSITORY_IS_CLEAN_AT_START=0
if [ $(git status --short | wc -l) = 0 ]; then
	REPOSITORY_IS_CLEAN_AT_START=1
fi

# Check if there are changes which were not pushed yet.
# If this is the case, the last commit is amended at the end of the run.
LAST_UPDATE_IS_PUSHED=0
if [ $(git log --oneline origin/master..HEAD | wc -l) = 0 ]; then
	LAST_UPDATE_IS_PUSHED=1
fi

# Check if the last commit was a submodule update.
# If this is the case, the last commit is amended at the end of the run.
LAST_COMMIT_IS_SUBMODULE_UPDATE=0
if git log --oneline -n 1 HEAD | egrep -q "Update submodules$"; then
	LAST_COMMIT_IS_SUBMODULE_UPDATE=1
fi

SKIP=0
if [ -n "$CONTINUE_FROM" ]; then
	SKIP=1
fi

for SUBMODULE in $(git submodule | awk '{print $2}'); do
	echo $SUBMODULE
	if [ $SUBMODULE = "$CONTINUE_FROM" ]; then
		SKIP=0
	fi
	if [ $SKIP = 1 ]; then
		continue
	fi
	echo "Entering '$SUBMODULE'"
	( cd $SUBMODULE && git pull )
done

echo
echo "==========================================="

# Check if the repository is clean (= if there were any changes).
# If this is the case, stop here.
if [ $(git status --short | wc -l) = 0 ]; then
	echo "DONE - No changes."
	exit 0
fi

if [ $REPOSITORY_IS_CLEAN_AT_START = 1 ]; then
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
