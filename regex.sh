#!/bin/bash

set -eu

export VERSION_REGEX='^[vV]?[0-9]+[.][0-9]+[.][0-9]+'
export VERSION_REGEX_FOR_SED='^\([vV]\?[0-9]\+[.][0-9]\+[.][0-9]\+\).\+'

export FULL_VERSION_REGEX='^[vV]?[0-9]+[.][0-9]+[.][0-9]+:[ ][0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'

