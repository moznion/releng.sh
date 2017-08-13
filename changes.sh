#!/bin/bash

set -eu

PWD=$(cd "$(dirname "$0")";pwd)

# shellcheck disable=SC1090,SC1091
source "$PWD/logger.sh"
# shellcheck disable=SC1090,SC1091
source "$PWD/regex.sh"
# shellcheck disable=SC1090,SC1091
source "$PWD/util.sh"
# shellcheck disable=SC1090,SC1091
source "$PWD/command.sh"

function get_end_of_dscr_line_num() {
  CHANGES_FILE=$1

  END_OF_DESCRIPTION_LINE_NUM=$(grep -n -E "$VERSION_REGEX" "$CHANGES_FILE" | head -1 | $SED_CMD -e 's/:.*//g')
  if [ -n "$END_OF_DESCRIPTION_LINE_NUM" ]; then
    END_OF_DESCRIPTION_LINE_NUM="$(echo '' | awk "{print $END_OF_DESCRIPTION_LINE_NUM - 1}")"
  else
    END_OF_DESCRIPTION_LINE_NUM="$(wc -l "$CHANGES_FILE" | awk '{print $1}')"
  fi

  echo "$END_OF_DESCRIPTION_LINE_NUM"
}

function is_valid_version_format() {
  VERSION=$1

  set +e
  _=$(echo "$VERSION" | grep -E "$VERSION_REGEX$")
  IS_INVALID=$?
  set -e

  if [ $IS_INVALID -gt 0 ]; then
    echo 0
  else
    echo 1
  fi
}

function get_next_version_line_num() {
  CHANGES_FILE=$1
  NEXT_VERSION_PLACEHOLDER=$2

  grep -n "$NEXT_VERSION_PLACEHOLDER" "$CHANGES_FILE" | head -1 | $SED_CMD -e 's/:.*//g'
}

function extract_description() {
  CHANGES_FILE=$1
  END_OF_DESCRIPTION_LINE_NUM=$2
  NEXT_VERSION_LINE_NUM=$3
  NEXT_VERSION_PLACEHOLDER=$4

  grep -A "$(echo '' | awk "{print $END_OF_DESCRIPTION_LINE_NUM - $NEXT_VERSION_LINE_NUM}")" "$NEXT_VERSION_PLACEHOLDER" "$CHANGES_FILE" | tail -n +2
}

### Main

if [ $# -lt 1 ]; then die "[ERROR] CHANGES file is not given\nUsage:\n\tchanges.sh /path/to/Changes/file"; fi

CHANGES_FILE="$1" # <= required
if [ ! -e "$CHANGES_FILE" ]; then die '[ERROR] Given CHANGES file is not found'; fi

set +u
NEXT_VERSION_VIA_CMD_ARG="$2" # <= optional
set -u

NEXT_VERSION_PLACEHOLDER='%%NEXT_VERSION%%'

# Use temporary file
TEMP_FILE="$(mktemp)"
cp "$CHANGES_FILE" "$TEMP_FILE"

NEXT_VERSION="$(read_next_version "$TEMP_FILE" "$NEXT_VERSION_VIA_CMD_ARG")"
END_OF_DESCRIPTION_LINE_NUM="$(get_end_of_dscr_line_num "$TEMP_FILE")"
NEXT_VERSION_LINE_NUM="$(get_next_version_line_num "$TEMP_FILE" "$NEXT_VERSION_PLACEHOLDER")"

DESCRIPTION="$(extract_description "$TEMP_FILE" "$END_OF_DESCRIPTION_LINE_NUM" "$NEXT_VERSION_LINE_NUM" "$NEXT_VERSION_PLACEHOLDER")"
while [ -z "$DESCRIPTION" ]; do # <= checks description is filled or not
  info "No description for next version in file: '$TEMP_FILE'"
  read -r -p "Edit file? [Y/n (default: Y)]: " EDIT_FILE
  if [ -z "$EDIT_FILE" ]; then
    # Default YES
    EDIT_FILE="y"
  fi

  if  [ "$EDIT_FILE" != 'y' ] && [ "$EDIT_FILE" != 'Y' ] ; then die "Aborted"; fi

  set +u
  if [ -z "$EDITOR" ]; then die "[ERROR] Environment variable '\$EDITOR' is not set, abort"; fi
  set -u

  $EDITOR "$TEMP_FILE"

  END_OF_DESCRIPTION_LINE_NUM="$(get_end_of_dscr_line_num "$TEMP_FILE")"
  NEXT_VERSION_LINE_NUM="$(get_next_version_line_num "$TEMP_FILE" "$NEXT_VERSION_PLACEHOLDER")"
  DESCRIPTION="$(extract_description "$TEMP_FILE" "$END_OF_DESCRIPTION_LINE_NUM" "$NEXT_VERSION_LINE_NUM" "$NEXT_VERSION_PLACEHOLDER")"
done

RELEASE_TIME=$($DATE_CMD -u +"%Y-%m-%dT%H:%M:%SZ")
$SED_CMD -i'' -e"s/$NEXT_VERSION_PLACEHOLDER/$NEXT_VERSION_PLACEHOLDER\n\n$NEXT_VERSION: $RELEASE_TIME/" "$TEMP_FILE"

cp "$TEMP_FILE" "$CHANGES_FILE"

echo -e "$DESCRIPTION"

