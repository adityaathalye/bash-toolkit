#!/usr/bin/env bash

set -euo pipefail

# Include all common utils first, such as logging
source "./logging.sh"


# ####################
# GLOBAL CONSTANTS
# ####################

# Allowed commands must exactly match terraform commands
declare -r allowed_commands=$(cat <<- 'ALLOWEDCMDS'
foo
bar
baz
quxx
ALLOWEDCMDS
        )


# ####################
# SCRIPT HELP
# ####################

usage() {
    cat <<- EOH

NAME

    ${0} - automate commands over the given target + environment combination.

SYNOPSIS

    \$ ${0} [command] [target] [environment]

DESCRIPTION

    Something meaningful. State prerequisites, pre-checks.

    Command is one of  : $(echo $allowed_commands | sed 's/\s/, /g')

EXAMPLES

    \$ ${0} -h|--help
           For help

    \$ ${0} foo targetName sandbox
           Execute "foo" command for all targets in the "sandbox" environment.

EOH
}


# ####################
# SCRIPT INPUTS (MANDATORY)
# ####################

trap usage EXIT SIGINT SIGTERM # ensure usage auto-prints if required args are missing

if [[ -z ${1:-} || ${1} == "-h" || ${1} == "--help" ]]
then exit
fi

declare -r command="${1:?$(log_error Required argument missing: 'command'.)}"
declare -r target="${2:?$(log_error Required argument missing: 'target'.)}"
declare -r environment="${3:?$(log_error Required argument missing: 'environment'.)}"

trap - EXIT SIGINT SIGTERM # unset trap


# ####################
# CONSTRUCTED GLOBAL CONSTANTS
# ####################

# Constructed global constants
declare -r target_dir="path/to/${target}"
declare -r target_file="$target_dir/example.txt"
declare -r ROOT_DIR="$PWD"


# ####################
# PRE-RUN CHECKS and FAILSAFES
# ####################

trap usage EXIT # ensure usage auto-prints if we preemptively fail the script

# FAIL if unmet dependencies
ensure_dependencies # comes from ./bin/common_util_functions.sh

# FAIL if bad/disallowed command is provided
if [[ -z $(echo "$allowed_commands" | grep --regexp="^${command}\$") ]]
then log_fatal_die "Unrecognised command \"$command\". See usage."
fi

# FAIL if conventional infra list file is absent
if ! [[ -f "./$target_file" ]]
then log_fatal_die "Cannot find ./${target_file} for \"$target\" target."
fi

# FAIL destructive command invocations, if environment is production-like
if [[ ${command} == @(baz|quxx) ]] && [[ ${environment} == @(prod*|sandbox) ]]
then log_fatal_die "You are attempting to run a destructive command \"${command}\" against the production environment \"${environment}\"."
fi

trap - EXIT # release usage-printing trap we took previously on EXIT

# ####################
# LOGIC
# ####################

func1() {
    # do something
}

func2() {
    # do something else
}

func3() {
    # do something even better
}

# ####################
# EXECUTE!
# ####################

# Scary stateful stuff goes here
