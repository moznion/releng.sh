#!/bin/bash

set -eu

# shellcheck disable=SC1090,SC1091
source "$(cd "$(dirname "$0")";pwd)/logger.sh"

function die() {
  # Decorate string (make it red) and pass that to STDERR, after exit
  echo -e "\033[0;31m$*\033[m" >&2
  exit 1
}

function info() {
  echo -e "\033[0;36m$*\033[m" >&2
}

function warn() {
  echo -e "\033[0;35m$*\033[m" >&2
}

function get_default_next_version() {
  LATEST_VERSION="$1"

  DEFAULT_NEXT_VERSION='0.0.1'
  if [ -n "$LATEST_VERSION" ]; then
    SEMANTIC_VERSION_SPLIT_REGEX='^\([vV]\?[0-9]\+[.][0-9]\+\)[.]\([0-9]\+\).\+'
    MAJOR_MINOR=$(echo "$LATEST_VERSION" | $SED_CMD -e "s/$SEMANTIC_VERSION_SPLIT_REGEX/\1/")
    PATCH=$(echo "$LATEST_VERSION" | $SED_CMD -e "s/$SEMANTIC_VERSION_SPLIT_REGEX/\2/")
    DEFAULT_NEXT_VERSION="$MAJOR_MINOR.$(echo "$PATCH" | awk '{print $1 + 1}')"
  fi

  echo "$DEFAULT_NEXT_VERSION"
}

function get_end_of_dscr_line_num() {
  CHANGES_FILE=$1
  SED_CMD=$2
  VERSION_REGEX=$3

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
  VERSION_REGEX=$2

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

function read_next_version() {
  CHANGES_FILE=$1
  SED_CMD=$2
  VERSION_REGEX=$3
  VERSION_REGEX_FOR_SED=$4
  NEXT_VERSION_VIA_CMD_ARG=$5

  LATEST_VERSION=$(grep -E "$VERSION_REGEX" "$CHANGES_FILE" | head -1 | $SED_CMD -e "s/$VERSION_REGEX_FOR_SED/\1/")
  DEFAULT_NEXT_VERSION="$(get_default_next_version "$LATEST_VERSION")"

  if [ -n "$NEXT_VERSION_VIA_CMD_ARG" ]; then
    if [ "$(is_valid_version_format "$NEXT_VERSION_VIA_CMD_ARG" "$VERSION_REGEX")" -ne 1 ]; then
      die "[ERROR] Given next version does not conform to the version format: $NEXT_VERSION_VIA_CMD_ARG"
    fi
    NEXT_VERSION="$NEXT_VERSION_VIA_CMD_ARG"
  else
    while : ; do
      read -r -p "Next version [$DEFAULT_NEXT_VERSION]: " NEXT_VERSION
      if [ -n "$NEXT_VERSION" ]; then
        if [ "$(is_valid_version_format "$NEXT_VERSION" "$VERSION_REGEX")" -ne 1 ]; then
          warn "Given next version does not conform to the version format: $NEXT_VERSION"
          continue
        fi

        break
      else
        NEXT_VERSION="$DEFAULT_NEXT_VERSION"
        break
      fi
    done
  fi

  echo "$NEXT_VERSION"
}

function get_next_version_line_num() {
  CHANGES_FILE=$1
  NEXT_VERSION_PLACEHOLDER=$2
  SED_CMD=$3

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

if [ $# -lt 1 ]; then die "[ERROR] CHANGES file is not given\nUsage:\n\trelease.sh /path/to/Changes/file"; fi

CHANGES_FILE="$1" # <= required
if [ ! -e "$CHANGES_FILE" ]; then die '[ERROR] Given CHANGES file is not found'; fi

set +u
NEXT_VERSION_VIA_CMD_ARG="$2" # <= optional
set -u

# Normalize sed and date command
SED_CMD=''
DATE_CMD=''
if [[ $OSTYPE =~ 'darwin' ]]; then
  SED_CMD="$(which gsed)" || die '[ERROR] gsed command is not installed'
  DATE_CMD="$(which gdate)" || die '[ERROR] gdate command is not installed'
else
  SED_CMD="$(which sed)" || die '[ERROR] sed command is not installed'
  DATE_CMD="$(which date)" || die '[ERROR] date command is not installed'
fi

NEXT_VERSION_PLACEHOLDER='%%NEXT_VERSION%%'
VERSION_REGEX='^[vV]?[0-9]+[.][0-9]+[.][0-9]+'
VERSION_REGEX_FOR_SED='^\([vV]\?[0-9]\+[.][0-9]\+[.][0-9]\+\).\+'

# Use temporary file
TEMP_FILE="$(mktemp)"
cp "$CHANGES_FILE" "$TEMP_FILE"

NEXT_VERSION="$(read_next_version "$TEMP_FILE" "$SED_CMD" "$VERSION_REGEX" "$VERSION_REGEX_FOR_SED", "$NEXT_VERSION_VIA_CMD_ARG")"
END_OF_DESCRIPTION_LINE_NUM="$(get_end_of_dscr_line_num "$TEMP_FILE" "$SED_CMD" "$VERSION_REGEX")"
NEXT_VERSION_LINE_NUM="$(get_next_version_line_num "$TEMP_FILE" "$NEXT_VERSION_PLACEHOLDER" "$SED_CMD")"

while [ -z "$(extract_description "$TEMP_FILE" "$END_OF_DESCRIPTION_LINE_NUM" "$NEXT_VERSION_LINE_NUM" "$NEXT_VERSION_PLACEHOLDER")" ]; do # <= checks description is filled or not
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

  END_OF_DESCRIPTION_LINE_NUM="$(get_end_of_dscr_line_num "$TEMP_FILE" "$SED_CMD" "$VERSION_REGEX")"
  NEXT_VERSION_LINE_NUM="$(get_next_version_line_num "$TEMP_FILE" "$NEXT_VERSION_PLACEHOLDER" "$SED_CMD")"
done

RELEASE_TIME=$($DATE_CMD -u +"%Y-%m-%dT%H:%M:%SZ")
$SED_CMD -i'' -e"s/$NEXT_VERSION_PLACEHOLDER/$NEXT_VERSION_PLACEHOLDER\n\n$NEXT_VERSION: $RELEASE_TIME/" "$TEMP_FILE"

cp "$TEMP_FILE" "$CHANGES_FILE"

