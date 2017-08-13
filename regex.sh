#!/bin/bash

set -eu

export VERSION_REGEX='^[vV]?[0-9]+[.][0-9]+[.][0-9]+'
export VERSION_REGEX_FOR_SED='^\([vV]\?[0-9]\+[.][0-9]\+[.][0-9]\+\).\+'

