#!/bin/bash

DOCKER_CMD='docker'

if [ -z "$1" ]
  then
    echo "Please run with new version, for example: "
    echo "$ ./upgrade.sh 0.9.4"
    exit 1
fi

# update pkgver
CURRENT_VER=$(grep 'pkgver=' PKGBUILD | awk -F= '{print $2}')
NEW_VER=$1
echo "Replacing $CURRENT_VER with $NEW_VER"
sed -i "s/$CURRENT_VER/$NEW_VER/g" PKGBUILD || exit 1

# update sha265sums
echo "Updating sha265sums"
updpkgsums || exit 1

# test on docker
TEST_OUTPUT=$($DOCKER_CMD build -t docker-makepkg . && $DOCKER_CMD run --rm --name kobweb-test -v $PWD:/pkg -v /etc/pacman.d/mirrorlist:/etc/pacman.d/mirrorlist:ro docker-makepkg)
TEST_OUTPUT_FINAL=$(echo $TEST_OUTPUT | tail -1)
if [[ $TEST_OUTPUT_FINAL == *$NEW_VER* ]]; then
	# commit and push to aur
	echo "Test successful, commiting changes"
	git checkout master && \
	makepkg --printsrcinfo > .SRCINFO && \
	git add -f .SRCINFO PKGBUILD && \
	git diff --staged && \
	read -p "Commit and push? [y/n] " && \
		[[ $REPLY =~ ^[yY]$ ]] && \
	git commit -vm "Upgrade to version $NEW_VER" && \
	git push origin master
	git push origin_github master
else
	# print docker test output for inspection
	echo "Test failed, printing full test output..." && \
	git restore . && \
	echo $TEST_OUTPUT_FINAL
fi

# cleanup
echo "Cleaning up..." && \
CLEANUP_OUTPUT=$($DOCKER_CMD image rm docker-makepkg) && \
git checkout feature/upgrade-test-script && \
git merge master
