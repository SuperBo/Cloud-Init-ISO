#!/bin/bash
# MIT License. See LICENSE file.

case "$OSTYPE" in
	linux*)
		MKISO=genisoimage
		STAT="stat -c %s"
		;;
	darwin* | bsd*)
		MKISO=mkisofs
		STAT="stat -f %z"
		;;
	*)
		echo "unknown architecture"
		;;
esac

FILENAME='init.iso'

# if we are in a git repository, name the ISO after the branch, date, and short commit hash
if $(command -v CI); then
	echo "We are in a CI/build environment."
	FILENAME="$CI_COMMIT_REF_SLUG-init-$(date -u '+%Y%m%d').$CI_COMMIT_SHORT_SHA.iso"
else
	IS_GIT=$(git rev-parse --is-inside-work-tree 2> /dev/null)
	if [ $IS_GIT ]; then
		GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
		GIT_COMMIT=$(git rev-parse --short HEAD)
		DATE=$(date -u '+%Y%m%d')
		FILENAME="$(basename $GIT_BRANCH)-init-$DATE.$GIT_COMMIT.iso"
	fi
fi

if [ $# -eq 1 ]; then
	FILENAME=$1
	echo "Building image to $FILENAME ..."
elif [ $# -gt 1 ]; then
	echo 'Usage: ./build.sh [filename]'
	exit 1
else
	echo "Building image to $FILENAME ..."
fi

$MKISO -output $FILENAME -volid cidata -joliet -rock user-data meta-data 2>build.log

FILESIZE=$($STAT $FILENAME 2>/dev/null)
COLUMNS=$(tput cols)
if [[ $FILESIZE > 0 ]]; then
	printf '%s (%d bytes) ... done!\n' $FILENAME $FILESIZE
else
	printf 'Something went wrong while trying to make %s\n' $FILENAME
fi

