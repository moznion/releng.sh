#!/bin/bash

set -eu

# shellcheck disable=SC1090,SC1091
source "$PWD/logger.sh"
# shellcheck disable=SC1090,SC1091
source "$PWD/regex.sh"
# shellcheck disable=SC1090,SC1091
source "$PWD/command.sh"

function _get_default_next_version() {
  LATEST_VERSION="$1"

  DEFAULT_NEXT_VERSION='0.0.1'
  if [ -n "$LATEST_VERSION" ]; then
    SEMANTIC_VERSION_SPLIT_REGEX='^\([vV]\?[0-9]\+[.][0-9]\+\)[.]\([0-9]\+\)'
    MAJOR_MINOR=$(echo "$LATEST_VERSION" | $SED_CMD -e "s/$SEMANTIC_VERSION_SPLIT_REGEX/\1/")
    PATCH=$(echo "$LATEST_VERSION" | $SED_CMD -e "s/$SEMANTIC_VERSION_SPLIT_REGEX/\2/")
    DEFAULT_NEXT_VERSION="$MAJOR_MINOR.$(echo "$PATCH" | awk '{print $1 + 1}')"
  fi

  echo "$DEFAULT_NEXT_VERSION"
}

function _is_valid_version_format() {
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


function read_next_version() {
  CHANGES_FILE=$1
  NEXT_VERSION_VIA_CMD_ARG=$2

  LATEST_VERSION=$(grep -E "$VERSION_REGEX" "$CHANGES_FILE" | head -1 | $SED_CMD -e "s/$VERSION_REGEX_FOR_SED/\1/")
  DEFAULT_NEXT_VERSION="$(_get_default_next_version "$LATEST_VERSION")"

  if [ -n "$NEXT_VERSION_VIA_CMD_ARG" ]; then
    if [ "$(_is_valid_version_format "$NEXT_VERSION_VIA_CMD_ARG")" -ne 1 ]; then
      die "[ERROR] Given next version does not conform to the version format: $NEXT_VERSION_VIA_CMD_ARG"
    fi
    NEXT_VERSION="$NEXT_VERSION_VIA_CMD_ARG"
  else
    while : ; do
      read -r -p "Next version [$DEFAULT_NEXT_VERSION]: " NEXT_VERSION
      if [ -n "$NEXT_VERSION" ]; then
        if [ "$(_is_valid_version_format "$NEXT_VERSION" "$VERSION_REGEX")" -ne 1 ]; then
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

