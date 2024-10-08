#!/usr/bin/env bash

#
# APT.
# sudo you speak it?
#

apt_install_standard_packages() {
    declare -A installed_name_to_apt_package_array=(
        [chromium]="chromium-browser"
        [curl]="curl"
        [emacs26]="emacs26"
        [ffmpeg]="ffmpeg"
        [flatpak]="flatpak"
        [gawk]="gawk"
        [git]="git"
        [gnome-tweaks]="gnome-tweak-tool"
        [gparted]="gparted"
        [jq]="jq"
        [kazam]="kazam"
        [java]="openjdk-8-jdk openjdk-11-jdk openjdk-14-jdk"
        [psql]="postgresql"
        [python3]="python3"
        [pip3]="python3-pip"
        [rlwrap]="rlwrap"
        [ag]="silversearcher-ag"
        [tmux]="tmux"
        [vim]="vim"
    )

    sudo add-apt-repository universe
    sudo add-apt-repository multiverse
    sudo add-apt-repository -y ppa:kelleyk/emacs
    sudo apt-get update

    for package in "${!installed_name_to_apt_package_array[@]}"
    do if which ${package} > /dev/null
       then printf "Skipping %s \n" ${package}
       else sudo apt-get install -y "${installed_name_to_apt_package_array[${package}]}"
       fi
    done
}

__apt_install_docker() {
    # Installation instructions copied from:
    # cf. https://docs.docker.com/engine/install/ubuntu/
    if ! which docker docker-engine docker.io containerd runc > /dev/null
    then # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update

        # Install docker
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Check install
        docker run hello-world
    fi
}

__apt_install_custom_nextdns() {
    # https://github.com/nextdns/nextdns/wiki/Debian-Based-Distribution
    if ! which nextdns > /dev/null
    then sh -c "$(curl -sL https://nextdns.io/install)"
    fi
}

__apt_install_custom_jami_p2p_videoconf() {
    # https://jami.net/download-jami-linux/
    sudo apt install gnupg dirmngr ca-certificates curl --no-install-recommends
    curl -s https://dl.jami.net/public-key.gpg | sudo tee /usr/share/keyrings/jami-archive-keyring.gpg > /dev/null
    sudo sh -c "echo 'deb [signed-by=/usr/share/keyrings/jami-archive-keyring.gpg] https://dl.jami.net/nightly/ubuntu_20.04/ ring main' > /etc/apt/sources.list.d/jami.list"
    sudo apt-get update && sudo apt-get install jami
}

__apt_install_custom_syncthing() {
    # https://apt.syncthing.net/

    if ! which syncthing > /dev/null
       then
           # Add the release PGP keys:
           sudo curl -s -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg

           # Add the "stable" channel to your APT sources:
           echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" |
               sudo tee /etc/apt/sources.list.d/syncthing.list

           # Add the "candidate" channel to your APT sources:
           echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing candidate" |
               sudo tee /etc/apt/sources.list.d/syncthing.list

           # Increase preference of Syncthing's packages ("pinning")
           printf "Package: *\nPin: origin apt.syncthing.net\nPin-Priority: 990\n" | sudo tee /etc/apt/preferences.d/syncthing

           # Update and install syncthing:
           sudo apt-get update
           sudo apt-get install syncthing
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

__snap_install_VSCode() {
    sudo snap install code --classic
}

sudo_install_from_walled_gardens() {
    __apt_install_custom_nextdns
    __apt_install_custom_syncthing
    __dpkg_install_chrome
    __snap_install_VSCode
    # TODO: install docker
    # TODO: install nvm (node version manager) https://github.com/nvm-sh/nvm#installing-and-updating
    # TODO: install node with nvm https://github.com/nvm-sh/nvm#usage
    # TODO: install yarn (package manager for JS)  _WITHOUT_ node https://classic.yarnpkg.com/en/docs/install#debian-stable
    # TODO: install shadow-cljs if needed https://docs.cider.mx/cider/cljs/shadow-cljs.html
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
    then printf "INFO: About to install packages from %s.\n" "${remote_name}"
    else printf "INFO: About to add remote with name %s.\n" "${remote_name}"
         flatpak remote-add --if-not-exists \
                 "${remote_name}" \
                 "https://flathub.org/repo/flathub.flatpakrepo"
    fi
}

flatpak_install_packages() {
    local flatpak_aliases_file="$HOME/.bash_aliases_flatpak"

    declare -A app_alias_to_app_ID_array=(
        [bitwarden]="com.bitwarden.desktop"
        [bookworm]="com.github.babluboy.bookworm"
        [dropbox]="com.dropbox.Client"
        [gimp]="org.gimp.GIMP"
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
    touch -m "${flatpak_aliases_file}"
    cat /dev/null > "${flatpak_aliases_file}.tmp"

    cat "${flatpak_aliases_file}" |
        __ensure_distinct |
        tee "${flatpak_aliases_file}.tmp" > /dev/null

    # check app alias, and flatpak install if not already apt installed
    for app_alias in "${!app_alias_to_app_ID_array[@]}"
    do if which "${app_alias}" > /dev/null ||
               grep -q -E "${app_alias}" "${flatpak_aliases_file}.tmp"
       then printf "Skipping flatpak install of ${app_alias}.\n"
       else printf "About to install ${app_alias_to_app_ID_array[${app_alias}]}.\n"
            flatpak install -y flathub "${app_alias_to_app_ID_array[${app_alias}]}"
            cat >> "${flatpak_aliases_file}.tmp" <<EOF
alias ${app_alias}='flatpak run ${app_alias_to_app_ID_array[${app_alias}]}'
EOF
        fi
    done

    # update bash aliases file, with revised flatpak apps
    cat "${flatpak_aliases_file}.tmp" |
        __ensure_distinct |
        tee "${flatpak_aliases_file}" > /dev/null

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

__install_to_HOME_bin_ngrok() {
    if ! which ngrok > /dev/null
    then cd "$HOME/Downloads"
         curl https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o "./ngrok-stable-linux-amd64.zip"
         unzip "./ngrok-stable-linux-amd64.zip"
         mv "./ngrok" "$HOME/bin/ngrok"
    fi
}

__install_to_HOME_bin_babashka() {
    # ref: https://raw.githubusercontent.com/babashka/babashka/master/install
    if ! which bb > /dev/null
    then
        local version="$(curl -sL https://raw.githubusercontent.com/babashka/babashka/master/resources/BABASHKA_RELEASED_VERSION)"
        local tar_file="babashka-${version}-linux-amd64-static.tar.gz"
        local sha_file="${tar_file}.sha256"
        local uri_path="https://github.com/babashka/babashka/releases/download/v${version}/"
         cd "$HOME/Downloads"
         curl -o "./${tar_file}" -sL "${uri_path}/${tar_file}"
         curl -o "./${sha_file}" -sL "${uri_path}/${sha_file}"

         printf "%s %s" "$(cat ${sha_file})" ${tar_file} |
             sha256sum --check --status &&
             tar -zxf "./${tar_file}" &&
             mv -f "./bb" "$HOME/bin/bb"
    fi
}

install_to_HOME_bin() {
    mkdir -p "$HOME/bin"
    __install_to_HOME_bin_youtube_dl
    __install_to_HOME_bin_clojure_things
    __install_to_HOME_bin_and_local_python_things
    __install_to_HOME_bin_ngrok
    __install_to_HOME_bin_babashka
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
