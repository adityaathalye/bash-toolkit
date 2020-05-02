#!/usr/bin/env bash

# clj-kondo setup

clj_kondo_install() {
    # Adapted from:
    # https://raw.githubusercontent.com/borkdude/clj-kondo/master/script/install-clj-kondo
    case "$(uname -s)" in
        Linux*)     local platform="linux";;
        Darwin*)    local platform="macos";;
    esac
    local latest_release="$(curl -s https://raw.githubusercontent.com/borkdude/clj-kondo/master/resources/CLJ_KONDO_RELEASED_VERSION)"
    local dl_archive_name="clj-kondo-${latest_release}-${platform}-amd64"
    local dl_archive_url="https://github.com/borkdude/clj-kondo/releases/download/v${latest_release}/${dl_archive_name}.zip"
    local dl_to_path="${HOME}/Downloads/${dl_archive_name}.zip"

    if which clj-kondo > /dev/null
    then local executable_bin_path="$(which clj-kondo)"
         local executable_version="$(clj-kondo --version | sed -e 's/clj-kondo v//g')"
    else local executable_bin_path="${HOME}/bin/clj-kondo"
    fi

    # Install IFF local version is stale. We rely on this check working:
    # [[ "2020.05.04" > "2020.05.03" ]] && echo higher
    # [[ "2020.05.04" > ""           ]] && echo higher
    if [[ ${latest_release} > ${executable_version} ]]; then
        if ! [[ -f "${dl_to_path}" ]]
        then printf "%s\n" "Downloading ${dl_archive_url} to ${dl_to_path}"
             curl -o "${dl_to_path}" -sL "${dl_archive_url}"
        fi

        mkdir -p "/tmp/${dl_archive_name}"
        unzip -o "${dl_to_path}" -d "/tmp/${dl_archive_name}"

        if [[ -f ${executable_bin_path} ]]
        then printf "%s\n" "Backing up ${executable_bin_path}"
             cp "${executable_bin_path}" "${executable_bin_path}.old"
        fi

        printf "%s\n" "Replacing ${executable_bin_path}"
        mv -f "/tmp/${dl_archive_name}/clj-kondo" "${executable_bin_path}"
        chmod 0700 "${executable_bin_path}"

        printf "%s\n" "Cleanup tmp and old files"
        rm -rv "/tmp/${dl_archive_name}"

        if [[ -f "${executable_bin_path}.old" ]]
        then printf "%s\n" "Old clj-kondo version was $(${executable_bin_path}.old --version)"
             rm -v "${executable_bin_path}.old"
        fi
        printf "%s\n" "New clj-kondo version is $(clj-kondo --version)"
    else
        printf "%s\n" "clj-kondo is already at the latest version: ${executable_version}"
    fi
}

clj_project_qmark() {
    # USAGE:
    #
    #     ls_git_projects /path/to/repos/ | clj_project_qmark
    #

    while read _wd
    do
        if [[ -f "${_wd}/project.clj" || -f "${_wd}/deps.edn" || -f "${_wd}/build.boot" ]]
        then printf "%s\n" "${_wd}"
        fi
    done
}

clj_project_classpath() {
    local _wd="${1:-$(pwd)}"

    __err() {
        1>&2 printf "%s\n" "Could not get classpath with ${1}"
        return 1
    }

    (
        cd ${_wd}
        if which lein > /dev/null
        then lein classpath 2> /dev/null || __err "lein"
        elif which boot > /dev/null
        then boot with-cp -w -f - 2> /dev/null || __err "boot"
        elif which clojure > /dev/null
        then clojure -Spath 2> /dev/null || __err "clojure cli"
        else __err "any standard tool (lein, boot, clojure cli)."
        fi
    )
}

clj_kondo_init() {
    # USAGE:
    #
    #     ls_git_projects /path/to/repos/ | clj_project_qmark | clj_kondo_init
    #
    # Init current dir, assuming at root of clojure project.
    # ref: https://github.com/borkdude/clj-kondo/blob/master/README.md#project-setup
    set -o pipefail

    while read _wd
    do local _classpath="$(clj_project_classpath ${_wd})"
       if [[ -n ${_classpath} ]]
       then 1>&2 printf "%s\n" "About to init clj-kondo for ${_wd}"
            mkdir -p ".clj-kondo"
            (cd ${_wd}; clj-kondo --lint "${_classpath}") | grep "linting took"
       fi
    done
}
