#!/usr/bin/env bash

# USAGE
#
# Source to cmd-line or in your file and use the functions.
#
#    log_info "Hello, this is a log line."
#    log_warn "You are in dangerous territory."
#    log_error "You screwed up"
#    log_fatal_die "It's so bad I can't continue."
#
# Intended for userland scripts / "application-level" logging, where
# writing to system logs is overkill. Prefer the 'logger' coreutil if
# your scripting demands "production-grade" logging.
#

__to_stderr() {
    # Ref: I/O Redirection: http://tldp.org/LDP/abs/html/io-redirection.html
    1>&2 printf "%s\n" "$(date --iso-8601=seconds) $@"
}

log_info() {
    __to_stderr "$(echo "INFO $0 $@")"
}

log_warn() {
    __to_stderr "$(echo "WARN $0 $@")"
}

log_error() {
    __to_stderr "$(echo "ERROR $0 $@")"
    return 1
}

log_fatal_die() {
    echo "FATAL $0 cannot proceed. Please fix errors and retry. $@"
    exit 1
}
