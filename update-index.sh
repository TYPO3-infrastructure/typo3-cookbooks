#!/bin/bash

export LANG=C

GITHUB_USER="typo3-cookbooks"

curl -s "https://api.github.com/users/${GITHUB_USER}/repos?per_page=10000" \
	| grep "ssh_url" \
	| awk -F\" '{print $4}' \
	| while read REPOSITORY; do

	# Skip myself
	if [ $REPOSITORY = "git@github.com:TYPO3-cookbooks/index.git" ]; then continue; fi

	git submodule add --quiet --force $REPOSITORY 2>&1 | grep -v "already exists in the index"
done
