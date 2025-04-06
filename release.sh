#!/bin/bash

# Script to create a GitHub release

# Configuration
CURRENT_TIME=$(date +"%Y-%m-%dT%H-%M-%S")
REPO_OWNER="nuts4nuts4nuts"
REPO_NAME="flappyversary"
TAG_NAME="v$CURRENT_TIME"
RELEASE_NAME="Version $TAG_NAME"
RELEASE_BODY="Automated release."
DRAFT=false
PRERELEASE=true

# Construct the gh release create command
GH_COMMAND="gh release create $TAG_NAME --repo $REPO_OWNER/$REPO_NAME --title '$RELEASE_NAME' --notes '$RELEASE_BODY'"

# Add flags for draft and prerelease if needed
if [ "$DRAFT" = "true" ]; then
  GH_COMMAND="$GH_COMMAND --draft"
fi

if [ "$PRERELEASE" = "true" ]; then
  GH_COMMAND="$GH_COMMAND --prerelease"
fi

# Execute the command
echo "Executing: $GH_COMMAND"
eval $GH_COMMAND

# Check the exit code
if [ $? -ne 0 ]; then
  echo "Failed to create release."
  exit 1
fi

# Create the Android build
ANDROID_TARGET=build/android/gravitygame.apk
godot --export-release "Android" "$ANDROID_TARGET"

# AINT NO WAY TO JUST UPLOAD AN IOS BUILD AFAIK

# Upload the binaries
gh release upload "$TAG_NAME" "$ANDROID_TARGET" --repo "$REPO_OWNER/$REPO_NAME"

# Check if the upload was successful
if [ $? -ne 0 ]; then
  echo "Error uploading binaries."
  exit 1
fi

necho "Release '$RELEASE_NAME' created with binaries!"
