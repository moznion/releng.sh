#!/bin/bash

set -eu

PWD=$(cd "$(dirname "$0")";pwd)

# shellcheck disable=SC1090,SC1091
source "$PWD/logger.sh"
# shellcheck disable=SC1090,SC1091
source "$PWD/util.sh"

set +u
if [ "$1" == "--init" ]; then
  PROJECT_NAME="$2"
  CHANGES_FILE="$3"
  if [ -z "$PROJECT_NAME" ] || [ -z "$CHANGES_FILE" ]; then
    die "[ERROR] Failed to initialize because description is missing\nUsage example:\n\trelease.sh --init 'YOUR-PROJECT-NAME' '/path/to/Changes/file'"
  fi
  cat <<EOS > "$CHANGES_FILE"
Revision history for $PROJECT_NAME

%%NEXT_VERSION%%

EOS
  info 'Initialized!'
  exit 0
fi
set -u

if [ $# -lt 1 ]; then die "[ERROR] CHANGES file is not given\nUsage:\n\trelease.sh /path/to/Changes/file"; fi

CHANGES_FILE="$1" # <= required
if [ ! -e "$CHANGES_FILE" ]; then die '[ERROR] Given CHANGES file is not found'; fi

set +u
NEXT_VERSION_VIA_CMD_ARG="$2" # <= optional
set -u

set +u
if [ -z "$GITHUB_TOKEN" ]; then die "[ERROR] Environment variable '\$GITHUB_TOKEN' is not set, abort"; fi
set -u

if [ -n "$(git status -suno)" ]; then
  die "[ERROR] Uncommitted files of git exists"
fi

NEXT_VERSION="$(read_next_version "$CHANGES_FILE" "$NEXT_VERSION_VIA_CMD_ARG")"

"$PWD/changes.sh" "$CHANGES_FILE" "$NEXT_VERSION"

VERSIONS="$(grep -n -E "$FULL_VERSION_REGEX" < "$CHANGES_FILE" | tr -s ':' ' ')"
VERSIONS_NUM="$(echo "$VERSIONS" | wc -l)"

LATEST_VERSION_LINE_NUM=$(echo "$VERSIONS" | head -1 | awk '{print $1}')
BEGIN="$(echo "$LATEST_VERSION_LINE_NUM" | awk '{print $1+1}')"

PREVIOUS_VERSION_LINE_NUM=''
if [ "$VERSIONS_NUM" -gt 1 ]; then
  PREVIOUS_VERSION_LINE_NUM=$(echo "$VERSIONS" | head -2 | tail -1 | awk '{print $1}')
else
  # First time
  PREVIOUS_VERSION_LINE_NUM=$(wc -l "$CHANGES_FILE" | awk '{print $1}')
fi

END="$(echo "$PREVIOUS_VERSION_LINE_NUM" | awk '{print $1-1}')"
DESCRIPTION="$($SED_CMD -n "$BEGIN","$END"p "$CHANGES_FILE" | tr '\n' "\\" | $SED_CMD 's/\\/\\n/g')"

GIT_REMOTE_INFO="$(git remote show origin)"

REPO_URL="$(echo "$GIT_REMOTE_INFO" | grep 'Fetch URL:' | $SED_CMD -e 's/[ ]*Fetch[ ]URL:[ ]*\(.\+\)/\1/')"
GIT_REMOTE_REGEX='.*github.com[/:]\([^/]\+\)\/\(.\+\)$'
OWNER="$(echo "$REPO_URL" | $SED_CMD -e "s/$GIT_REMOTE_REGEX/\1/")"
REPO="$(echo "$REPO_URL" | $SED_CMD -e "s/$GIT_REMOTE_REGEX/\2/" | $SED_CMD -e "s/\(.\+\)\([.]git\)$/\1/")"

git commit "$CHANGES_FILE" -m "Releng: $NEXT_VERSION"
git tag "$NEXT_VERSION"
git push origin "$NEXT_VERSION"

JSON=$(cat << EOS
{
  "tag_name": "$NEXT_VERSION",
  "target_commitish": "master",
  "name": "$NEXT_VERSION",
  "body": "$DESCRIPTION",
  "draft": false,
  "prerelease": false
}
EOS
)

curl -XPOST -H "Authorization: token $GITHUB_TOKEN" -d "$JSON" "https://api.github.com/repos/$OWNER/$REPO/releases"

