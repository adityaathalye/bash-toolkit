#!/usr/bin/env bash

#
# APT.
# sudo you speak it?
#

apt_install_standard_packages() {
    local apt_packages="chromium-browser
curl
emacs26
ffmpeg
flatpak
gawk
git
gnome-tweak-tool
gparted
jq
kazam
openjdk-8-jdk
openjdk-11-jdk
openjdk-14-jdk
postgresql
python3
python3-pip
python3-venv
rlwrap
tmux
vim"
    sudo add-apt-repository universe
    sudo add-apt-repository multiverse
    sudo add-apt-repository -y ppa:kelleyk/emacs
    sudo apt-get update

    for package in ${apt_packages}
    do if ! which ${package} > /dev/null
       then sudo apt-get install -y ${package}
       fi
    done
}

__apt_install_custom_nextdns() {
    # https://github.com/nextdns/nextdns/wiki/Debian-Based-Distribution
    if ! which nextdns > /dev/null
    then sh -c "$(curl -sL https://nextdns.io/install)"
    fi
}

__dpkg_install_chrome() {
    if ! which google-chrome > /dev/null
    then curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
              -o "$HOME/Downloads/google-chrome-stable_current_amd64.deb"
         sudo dpkg -i "$HOME/Downloads/google-chrome-stable_current_amd64.deb"
         sudo apt-get -f install
    fi
}

sudo_install_from_walled_gardens() {
    __apt_install_custom_nextdns
    __dpkg_install_chrome

    sudo apt autoremove
    sudo apt autoclean
}

#
# FLATPACK.
# OH: "flatpack is the Glorious Future"
#

flatpak_install_packages_repo_with_restart() {
    # BEFORE ANYTHING ELSE
    # - Ensure flatpak remote repos configured.
    # - Trigger restart iff first-time configuration.
    local remote_name="flathub"
    if flatpak remotes --columns=name | grep -q "${remote_name}"
    then printf "INFO: About to install packages from %s\n" "${remote_name}"
    else printf "INFO: About to add remote with name %s, and RESTART!\n" "${remote_name}"
         flatpak remote-add --if-not-exists \
                 "${remote_name}" \
                 "https://flathub.org/repo/flathub.flatpakrepo"
         shutdown -r
    fi
}

flatpak_install_packages() {
    local flatpak_aliases_file="$HOME/.bash_aliases_flatpak"
    declare -A app_alias_to_app_ID_array=(
        [bitwarden]="com.bitwarden.desktop"
        [bookworm]="com.github.babluboy.bookworm"
        [dropbox]="com.dropbox.Client"
        [gimp]="org.gimp.GIMP"
        [gnome-font-viewer]="org.gnome.font-viewer"
        [inkscape]="org.inkscape.Inkscape"
        [keepassx]="org.keepassxc.KeePassXC"
        [postman]="com.getpostman.Postman"
        [scribus]="net.scribus.Scribus"
        [skype]="com.skype.Client"
        [slack]="com.slack.Slack"
        [vlc]="org.videolan.VLC"
        [xournal]="net.sourceforge.xournal"
        [zeal]="org.zealdocs.Zeal"
        [zoom]="us.zoom.Zoom"
    )

    __ensure_distinct() { tr -s '\n' | sort | uniq ; }

    # set up to update bash aliases file, for flatpak apps
    touch "${flatpak_aliases_file}"
    cat "${flatpak_aliases_file}" |
        __ensure_distinct > "${flatpak_aliases_file}.tmp"

    # check app alias, and flatpak install if not already apt installed
    for app_alias in "${!app_alias_to_app_ID_array[@]}"
    do  if which ${app_alias} > /dev/null
        then printf "Skipping flatpak install of ${app_alias}, because %s.\n" \
                    "$(type -a ${app_alias})"
        else echo "${app_alias_to_app_ID_array[${app_alias}]}"
             flatpak install -y flathub "${app_alias_to_app_ID_array[${app_alias}]}"
             cat >> "${flatpak_aliases_file}.tmp" <<EOF
alias ${app_alias}='flatpak run ${app_alias_to_app_ID_array[${app_alias}]}'
EOF
        fi
    done

    # update bash aliases file, with revised flatpak apps
    cat "${flatpak_aliases_file}.tmp" |
        __ensure_distinct > "${flatpak_aliases_file}"

    # cleanup tmp file
    rm "${flatpak_aliases_file}.tmp"
}

#
# HOME bin HOME.
# Keep it in the userspace.
#

__install_to_HOME_bin_youtube_dl() {
    if ! which youtube-dl > /dev/null
    then curl -L https://yt-dl.org/downloads/latest/youtube-dl -o "${HOME}/bin/youtube-dl"
         chmod u+x "${HOME}/bin/youtube-dl"
    fi
}

__install_to_HOME_bin_clojure_things() {
    # leiningen
    if ! which lein > /dev/null
    then curl https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -o "$HOME/bin/lein"
         chmod u+x "$HOME/bin/lein"
         "$HOME/bin/lein"
    fi
    # clj-kondo
    ( source ./clj-projects.sh
      clj_kondo_install )
}

__install_to_HOME_bin_and_local_python_things() {
    # get pipenv, virtualenv, and virtualenvwrapper
    # https://docs.python-guide.org/dev/virtualenvs/#
    which pipenv || pip3 install --user pipenv
    which virtualenv || pip3 install virtualenv
    which virtualenvwrapper.sh || pip3 install virtualenvwrapper
}

install_to_HOME_bin() {
    mkdir -p "$HOME/bin"
    __install_to_HOME_bin_youtube_dl
    __install_to_HOME_bin_clojure_things
    __install_to_HOME_bin_and_local_python_things
}

#
# CONFIGURATIONS.
# Are we there yet?
#

__configure_java_default_as_openjdk_11() {
    if ! java --version | grep -q "openjdk 11"
    then sudo update-java-alternatives \
              --set "$(update-java-alternatives --list | awk '/java-1.11.*-amd64/ { print $1 }')"
    fi
}

configure_things() {
    __configure_java_default_as_openjdk_11
}

#
# EXECUTE!
# Theirs not to make reply,
# Theirs not to reason why,
# Theirs but to do and die.
# Into the valley of Death
# Rode the six hundred.
#

apt_install_standard_packages

sudo_install_from_walled_gardens

install_to_HOME_bin

flatpak_install_packages_repo_with_restart
flatpak_install_packages

configure_things
