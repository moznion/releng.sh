#!/bin/bash

set -eu

# Normalize sed and date command
export SED_CMD
export DATE_CMD
if [[ $OSTYPE =~ 'darwin' ]]; then
  SED_CMD="$(which gsed)" || die '[ERROR] gsed command is not installed'
  DATE_CMD="$(which gdate)" || die '[ERROR] gdate command is not installed'
else
  SED_CMD="$(which sed)" || die '[ERROR] sed command is not installed'
  DATE_CMD="$(which date)" || die '[ERROR] date command is not installed'
fi

