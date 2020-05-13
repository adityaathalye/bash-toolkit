#!/usr/bin/env bash

source "${HOME}/bin/scripting-utils.sh"
source "${HOME}/bin/logging.sh"

# ####################
# DEPENDENCIES:
# - Warn about missing dependencies, at the time of sourcing the file.
# ####################

ensure_min_bash_version "4.4"
ensure_deps "gawk" "jq"


# ####################
# PURE FUNCTIONS: STRUCTURE-AGNOSTIC
# - Assume a record per line regardless of whether CSV, JSON, or plain old text
# - these must consume stdin and write to stdout/err, and/or
# - never cause side-effects (explicit file I/O etc.)
# ####################

deduplicate() {
    sort | uniq
}

frequencies() {
    # Given appropriately-sorted finite set of records via STDIN,
    # produce a frequency distribution of the records.
    # (Ref. Classic Shell Scripting)

    sort | uniq -c | sort -bnr
}

drop_first_n() {
    local lines="${1:-0}"
    local offset="$(( lines + 1 ))"

    tail -n +"${offset}"
}

drop_last_n() {
    local lines="${1:-0}"
    head -n -"${lines}"
}

drop_header_footer() {
    local header_lines="${1:?$(log_error "Header line count required, 1-indexed.")}"
    local footer_lines="${2:?$(log_error "Footer line count required, 1-indexed.")}"

    drop_first_n "${header_lines}" |
        drop_last_n "${footer_lines}"
}

window_from_to_lines() {
    local from_line="${1:?$(log_error "FROM line number required, 1-indexed.")}"
    local to_line="${2:?$(log_error "TO line number required, 1-indexed.")}"

    drop_first_n "${from_line}" |
        head -n "${to_line}"
}

