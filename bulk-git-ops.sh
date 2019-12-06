#!/usr/bin/env bash

source ./logging.sh

logdir="$HOME/.bulk_git_ops"

# SUMMARY
#
# If remote has new changes, git fetch origin would download objects
# and should cause mtime of .git to change. We can use this fact
# to filter active repos for update.
#
# Examples assume that repos you contribute to are spread across
# remote hosts, and (hopefully) namespaced sanely. I organise my
# sources as follows.
#
#   ~/src/{github,gitlab,bitbucket}/{usernames..}/{reponames..}

#
# USAGE
#
# Source the file, and use the functions as command line utilities as follows.
#
#   source ~/src/path/to/this/script/bulk-git-ops.sh
#
# QUERY: Count repos that are stale:
#
#   ls_git_projects ~/src/ | take_stale | count_repos_by_remote
#
# QUERY: Count repos that are active (within 12 hours by default):
#
#   ls_git_projects ~/src/ | take_active | count_repos_by_remote
#
#
# EXECUTE! Use 'xgit' to apply simple git commands to the given repos, with logs to STDERR/stty
#
#   ls_git_projects ~/src/bitbucket | xgit fetch # bitbucket-hosted repos
#
# EXECUTE! Use 'proc_repos' to apply custom functions to, with logs to STDERR/stty
#
#   ls_git_projects ~/src/bitbucket | proc_repos git_fetch # all repos
#   ls_git_projects ~/src/bitbucket | take_stale | proc_repos git_fetch # only stale repos
#   ls_git_projects ~/src/bitbucket | take_active | proc_repos git_fetch # only active repos
#
# EXECUTE! What's the current branch? Logs to STDERR/stty
#
#   ls_git_projects ~/src/bitbucket | proc_repos git_branch_current # all repos
#
# EXECUTE! With logs redirected to hidden dir for logging (you must create it by hand first)
#
#   mkdir -p "${logdir}"
#   ls_git_projects ~/src/bitbucket | proc_repos git_branch_current 2>> "${logdir}/bulkops.log"
#   tail "${logdir}/bulkops.log"
#

ls_git_projects() {
    # Spit out list of root dirs of .git-controlled projects
    local basedir="${1:-$PWD}"

    if [[ -d ${basedir} ]]
    then find ${basedir} -type d -name '.git' | xargs dirname | xargs realpath
    else >&2 printf "%s\n" "ERROR ${basedir} is not a valid base directory."
         return 1
    fi
}

identity() {
    printf "%s\n" "$@"
}

proc_repos() {
    # Apply any given operation on the given repos. Use in a pipeline.
    local func=${1:-identity}
    local repo_dir
    while read repo_dir
    do $func "${repo_dir}"
       log_info "Applied ${func} to ${repo_dir}"
    done
}

xgit() {
    # Apply a git operation on the given repos. Use in a pipeline.
    local git_cmd="${@}"
    local repo_dir
    while read repo_dir
    do git --git-dir="${repo_dir}/.git" $git_cmd
       log_info "Applied git ${git_cmd} to ${repo_dir}."
    done
}

# git_fetch_statuses() {
#     local basedir=${1:-"$PWD"}
#     find ${basedir} \
#          -type d -name '.git' \
#          -prune -print \
#          -execdir git fetch -q \;
# }

__with_git_dir() {
    local repo_dir="${1}"
    shift
    git --git-dir="${repo_dir}/.git" "$@"
}

git_fetch() {
    local repo_dir="${1}"
    __with_git_dir "${repo_dir}" fetch -q
}

git_status() {
    __with_git_dir "${1}" status
}

git_branch_current() {
    local repo_dir="${1}"
    __with_git_dir "${repo_dir}" rev-parse --abbrev-ref=strict HEAD
}

__is_repo_active() {
    # A directory's mtime increments only if files/sub-dirs are
    # created and/or deleted.
    #
    # We can use this plus the fact that the .git directory's
    # contents would change IFF new objects are created in it,
    # or old ones garbage collected.
    #
    # Fetch operations are idempotent, and no-ops if local has not
    # diverged from remote.
    #
    # Events we care about, to classify as "active":
    # - Fetch from remote updates .git
    # - Active development updates .git (stage/commit)
    #
    # Events that don't matter usually (infrequent), but are worth
    # interpreting as "active":
    #
    # - Objects collected / compacted automatically by git locally
    #
    local repo_dir="${1}"
    local stale_hrs="${2:-12}"
    local hrs_ago=$(( ($(date +%s)
                       - $(stat -c %Y "${repo_dir}/.git"))
                      / 3600 ))
    [[ $hrs_ago -le $stale_hrs ]]
}

take_active() {
    local repo_dir
    while read repo_dir
    do __is_repo_active "${repo_dir}" && printf "%s\n" "${repo_dir}"
    done
}

take_stale() {
    local repo_dir
    while read repo_dir
    do __is_repo_active "${repo_dir}" || printf "%s\n" "${repo_dir}"
    done
}

count_repos_by_remote() {
    grep -E -o "github|gitlab|bitbucket" | sort | uniq -c
}
