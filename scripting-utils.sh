#!/usr/bin/env bash

#
# DEPENDENCY CHECKS
#

ensure_deps() {
    # Given a list of dependencies, emit unmet dependencies to stderr,
    # and return 1. Otherwise silently return 0.
    local required_deps="${@}"
    local err_code=0
    for prog in ${required_deps}
    do if ! which "$prog" > /dev/null
       then 2>& printf "%s\n" "$prog"
            err_code=1
       fi
    done
    return ${err_code}
}

ensure_min_bash_version() {
    # Given a 'Major.Minor.Patch' SemVer number, return 1 if the system's
    # bash version is older than the given version. Default to 4.0.0.
    local semver=($(IFS='.' ; echo $1 ;));
    ! [[ ${BASH_VERSINFO[0]} -lt ${semver[0]:-4} ||
             ${BASH_VERSINFO[1]} -lt ${semver[1]:-0} ||
             ${BASH_VERSINFO[2]} -lt ${semver[2]:-0} ]]
}
