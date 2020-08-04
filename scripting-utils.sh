#!/usr/bin/env bash

#
# PATH MANAGEMENT
#

make_clean_PATH() {
    local my_path=${@:-"${PATH}"}

    printf "%s\n" ${my_path} |
        # un-form PATH-like strings
        tr ':' '\n' |
        # De-duplicate. # ref: https://stackoverflow.com/a/20639730
        # Or use awk '!x[$0]++', as explained here https://stackoverflow.com/a/11532197
        cat -n | sort -uk2 | sort -nk1 | cut -f2- |
        # re-form lines into single-colon-separated PATH-like string
        tr '\n' ':' | tr -s ':' |
        # ensure no trailing colons
        sed 's/:$//g'
}


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

#
# FUNCTION QUERIES and TRANSFORMS
#

fn_to_sh_syntax() {
    # Given a zsh-style or bash-style function definition, emit
    # an sh-style companion. I prefer to keep the opening brace
    # on the same line as the fn name and the body+closing braces
    # on the following lines, for cleaner regex-matching of fn
    # definitions. e.g.
    #
    #     'function foo3_bar() {' --> 'foo3_bar() {'
    #     'function foo3_bar {'   --> 'foo3_bar() {'
    #
    sed -E 's;(function)\s+(\w+)(\(\))?+\s+\{;\2() \{;' ;
}

fn_ls() {
    # List out names of functions found in the given files,
    # assuming well-formed function definitions, written as:
    #
    #     'foo3_bar() {'
    #
    grep -E -o "^(\w+)\(\)\s+\{" "$@" | tr -d '(){'
}
