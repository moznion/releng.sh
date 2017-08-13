#!/bin/bash

set -eu

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

