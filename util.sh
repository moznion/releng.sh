#!/bin/bash

set -eu

function read_next_version() {
  CHANGES_FILE=$1
  SED_CMD=$2
  NEXT_VERSION_VIA_CMD_ARG=$3

  LATEST_VERSION=$(grep -E "$VERSION_REGEX" "$CHANGES_FILE" | head -1 | $SED_CMD -e "s/$VERSION_REGEX_FOR_SED/\1/")
  DEFAULT_NEXT_VERSION="$(get_default_next_version "$LATEST_VERSION")"

  if [ -n "$NEXT_VERSION_VIA_CMD_ARG" ]; then
    if [ "$(is_valid_version_format "$NEXT_VERSION_VIA_CMD_ARG")" -ne 1 ]; then
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

