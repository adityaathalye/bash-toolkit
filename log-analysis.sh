#!/usr/bin/env bash

source "${HOME}/bin/scripting-utils.sh"
source "${HOME}/bin/logging.sh"

# ####################
# DEPENDENCIES:
# - Warn about missing dependencies, at the time of sourcing the file.
# ####################

ensure_min_bash_version "4.4"
ensure_deps "gawk" "jq"

