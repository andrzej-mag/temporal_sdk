#!/usr/bin/env bash
# Inspired by:
# https://github.com/welpo/release
# https://github.com/orhun/git-cliff/blob/main/release.sh

set -eu

VERSION_FORMAT="^v[0-9]+\.[0-9]+\.[0-9]+.*"

exit_with_message() {
	echo "$1" >&2
	exit 1
}

askYesNo() {
	question=$1
	default=$2
	if [ "$default" = true ]; then
		options="[Y/n]"
		default="y"
	else
		options="[y/N]"
		default="n"
	fi
	read -p "$question $options " -n 1 -s -r input
	input=${input:-${default}}
	echo "${input}"
	if [[ "$input" =~ ^[yY]$ ]]; then
		answer=true
	else
		answer=false
	fi
}

VERSION_TAG=$(mix version_tag)

# Verify that version tag matches the expected format.
if ! [[ $VERSION_TAG =~ $VERSION_FORMAT ]]; then
	exit_with_message "Version tag $VERSION_TAG does not match the expected format ${VERSION_FORMAT}."
fi

# Run only from the default branch.
default_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "$default_branch" ]; then
	echo "Not on the $default_branch branch, current branch: $default_branch."
	exit_with_message "Switch to the $default_branch before running this script."
fi

# Check for a clean working directory.
if [ -n "$(git status --porcelain)" ]; then
	echo "Your working directory is dirty."
	exit_with_message "Commit or stash your changes before running this script."
fi

# Ensure that local is up-to-date with remote.
if [ -n "$(git fetch --dry-run)" ]; then
	echo "Your local branch is ahead or behind of the remote."
	exit_with_message "Pull or push any changes before running this script."
fi

# Create git release tag message.
tag_msg=$(git cliff --config .github/cliff_tag.toml --unreleased --strip all --tag "$VERSION_TAG")
tput rev
echo "Release tag message:"
tput sgr0
echo "$tag_msg"
echo

# Update CHANGELOG.
git cliff --config .github/cliff_changelog.toml --tag "$VERSION_TAG"

echo "------------------------------------------------------------------------------------"
echo "Release $VERSION_TAG is ready. Verify output above and check CHANGELOG.md."
askYesNo "Proceed with git tag creation, git commit, git push and hex.publish" true

if [ "$answer" = true ]; then
	# Create a signed and annotated git tag.
	git tag --sign --annotate -m "$tag_msg" "$VERSION_TAG"

	# Git commit.
	git add -A
	git commit -m "🔖 chore(release): prepare for $VERSION_TAG"

	# Git push.
	git push
	git push --tags

	# Hex publish.
	mix hex.publish
fi
