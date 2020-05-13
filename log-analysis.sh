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


# ####################
# PURE FUNCTIONS: SINGLE and MULTI-LINE STRUCTURED RECORDS
# - filter, format, transform single or multi-line log streams
# - these must consume stdin and write to stdout/err, and/or
# - never cause side-effects (explicit file I/O etc.)
# ####################

logs_extract_records() {
    # Usage: cat ./logfile.log | extract_log_records | wc -l
    # or replace by awk if the pipeline gets too deep
    grep -E -v "REJECT_LINES_PATTERN" \
        | grep -E "CHOOSE_LINES_PATTERN"
}

logs_multiline_as_paras() {
    # Applications often print logs in multiple lines, and we face
    # walls of text.
    #
    # Given a wall of text of structured records, break the wall into
    # newline-separated paragraphs, for visual and structural separation.
    # Identify the beginning line, print a newline above it. Print
    # subsequent lines as-is, till the next paragraph begins.

    sed -n -E \
        -e 's;^(FIXME_PARA_START_PATTERN).*;\n\0;p' \
        -e 's;^([[:alnum:]]+.*);\0;p'
}

logs_paras_to_oneline() {
    # Given any paragraph-style multi-line record set, transform each
    # paragraph into single-line records.
    #
    # Ensure round trip from collapse -> expand -> collapse by using a
    # unique marker (like "^Z") to annotate the _beginning_ of each
    # line of a paragraph. (Ref. Classic Shell Scripting).

    awk 'BEGIN { RS = "" } { gsub("\n","^Z"); print; }'
}

logs_oneline_to_paras() {
    # Given a collapsed one-line record, expand it back to multi-line form.
    # BUT preserve the "paragraph separation", to help re-processing.

    awk 'BEGIN { ORS="\n\n"; } { gsub("\\^Z", "\n"); print; }'
}

logs_group_by_YYYY() {
    # Given a list of records of this structure:
    # INFO YYYYMMDDHHSS "Foobar important information"

    sort -b -k2.1,2.4 # Ignore leading blanks, for correct character indexing
}

logs_group_by_MM() {
    # Given a list of records of this structure:
    # INFO YYYYMMDDHHSS "Foobar important information"

    sort -b -k2.5,2.6
}

logs_group_by_MM_then_YYYY() {
    # Given a list of records of this structure:
    # INFO YYYYMMDDHHSS "Foobar important information"

    sort -b -k2.5,2.6 -k2.1,2.4
}

# ####################
# PURE FUNCTIONS: CSV RECORDS
# - make and select CSV records, one-per line, which
#   may or may not have header and footer
# - these must consume stdin and write to stdout/err, and/or
# - never cause side-effects (explicit file I/O etc.)
# ####################

csv_from_http_error_logs() {
    # Example for generating CSV data stream, assuming log files are
    # space-separated records.
    #
    # Usage: cat ./logfile.log | http_errors_to_csv > outfile.csv
    #
    # Suppose our log has the following format:
    #
    # Field Name   : Position in log line
    # timestamp    : 1
    # http method  : 2
    # http status  : 3
    # aws trace id : 5
    # customer ID  : 6
    # uri          : 7
    #
    # Once generated, the CSV (outfile.csv) may be further analyzed as follows:
    #
    # - Make frequency distribution of HTTP_status, found in column 2 of outfile
    #
    # $ cat outfile.csv \
        #   | awk 'BEGIN { FS="," } { print $2 }' \
        #   | drop_csv_header \
        #   | deduplicate \
        #   | frequencies
    #

    awk 'BEGIN { FS = "[[:space:]]+"; OFS = ","; print "Timestamp,HTTP_status,HTTP_method,URI,Customer_ID,AWS_Trace_ID"}
         /(GET|POST|PUT)[[:space:]]+(4|5)[[:digit:]][[:digit:]][[:space:]].*/ { sub(/^(\/common\/uri\/prefix\/)/, "", $7);
                                        print $1,$3,$2,$7,$6,$5;
                                        records_matched+=1; }'
}

csv_get_col() {
    local idx="${1}"
    cut -d , -f ${idx}
}

csv_prepend_colnames() {
    local colnames="${@}"
    cat <(printf "%s\t" ${colnames} printf "\n" ) -
}


# ####################
# PURE FUNCTIONS: JSON RECORDS
# - these must consume stdin and write to stdout/err, and/or
# - never cause side-effects (explicit file I/O etc.)
# ####################


jq_with_defaults() {
    # Wraps jq with defaults for the purpose of this program.
    # Expects to be passed a well-formed jq query as argument.
    #
    # Defaults provided:
    #
    # - Output with no colour, to avoid breaking tools that can't process colours
    # - Output as a single line, to preserve compatibility with unix tools
    jq -M -c "$@"
}


json_drop_uris() {
    # Given uri prefix path, and csv list of routes under the path, drop any
    # JSON log line that contains the path in its 'uri' field. Also drop any
    # JSON having null 'uri' value.

    local uri_prefix="${1:?(log_error 'Path of URI to drop required')}"
    local uri_routes="${2:?(log_error 'List of routes to drop (as nested under URI) required')}"
    local uri_routes_jq_pattern="$(printf "" "${uri_routes}" | tr ',' '\|')"

    log_info "Dropping irrelevant or empty uris."
    jq_with_defaults --arg ROUTES_REGEX "^/${uri_prefix}/${uri_routes_jq_pattern}.*" '. |
    select((."uri" == null) or ((."uri" | strings) | test($ROUTES_REGEX) | not))'
}
