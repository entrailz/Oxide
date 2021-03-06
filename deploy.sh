#!/bin/bash

function die_with { echo "$*" >&2; exit 1; }

echo "Are you Travis?"
if [ ! $TRAVIS ]; then die_with "You are not Travis!"; fi

echo "Checking if commit is a pull request"
if [ $TRAVIS_PULL_REQUEST == true ]; then die_with "Skipping deployment for pull request!"; fi

echo "Configuring git credentials"
git config --global user.email "travis@travis-ci.org" || die_with "Failed to configure git user email!"
git config --global user.name "Travis" || die_with "Failed to configure git user name!"

echo "Cloning snapshots branch using token"
GIT_REPO="https://$GITHUB_TOKEN@github.com/OxideMod/Snapshots.git"
git clone -q $GIT_REPO $HOME/Snapshots >/dev/null || die_with "Failed to clone snapshots repository!"

echo "Bundling and compressing files"
for d in Bundles/*; do
    GAME="${d##*/}"
    cd Bundles/$GAME && zip -FS -vr9 $HOME/Snapshots/Oxide-$GAME.zip . || die_with "Failed to bundle files!"
    cd $TRAVIS_BUILD_DIR
done

echo "Adding, committing, and deploying snapshots"
cd $HOME/Snapshots || die_with "Failed to change to snapshots directory!"
git add . || die_with "Failed to add files for commit!"
COMMIT_MESSAGE="Oxide build $TRAVIS_BUILD_NUMBER from https://github.com/$TRAVIS_REPO_SLUG/commit/${TRAVIS_COMMIT:0:7}"
git commit -m "$COMMIT_MESSAGE" || die_with "Failed to commit files!"
git push -q origin master >/dev/null || die_with "Failed to push snapshots to GitHub!"

echo "Deployment cycle completed. Happy developing!"
