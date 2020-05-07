#!/bin/bash

is_vim_install=0

command -v sha1sum >/dev/null 2>&1 || {
    echo "Error: command sha1sum not found"
    # should be installed on linux
    if [[ "$OSTYPE" == "darwin"* ]]
    then
        echo "brew install md5sha1sum"
    fi
    exit 1
}

function install_tool() {
    local tool
    tool="$1"
    if [[ "$OSTYPE" == "darwin"* ]]
    then
        brew install "$tool"
    else
        if [ "$UID" == "0" ]
        then
            apt install "$tool"
        else
            if [ -x "$(command -v sudo)" ]
            then
                sudo apt install "$tool"
            else
                echo "[!] Error: install sudo"
                exit 1
            fi
        fi
    fi
}

function install_vim() {
    if [ -x "$(command -v vim)" ] && vim --version | grep -q 'Linking.*python'
    then
        echo "[*] vim with python support found"
    else
        echo "[*] no vim with python support found!"
        echo "[*] installing vim and dependencys ..."
        is_vim_install=1
        if [[ "$OSTYPE" == "darwin"* ]]
        then
            echo "[!] Warning: darwin is not supported!"
            return
        fi
        if [ "$UID" == "0" ]
        then
            apt install vim-nox curl git build-essential cmake python3 python3-dev ctags cscope shellcheck
        else
            if [ -x "$(command -v sudo)" ]
            then
                sudo apt install vim-nox curl git build-essential cmake python3 python3-dev ctags cscope shellcheck
            else
                echo "[!] Error: install sudo"
                exit 1
            fi
        fi
    fi
}

function check_dotfile_version() {
    local dotfile
    local dotfile_path
    local versionfile
    local aVersions=()
    local aSha1s=()
    dotfile="$1"
    dotfile_repo="$2"
    dotfile_path="$3"
    versionfile=dev/${dotfile}_versions.txt

    if [ ! -f "$versionfile" ]
    then
        echo "Error: $versionfile not found"
        exit
    fi

    while read -r line; do
        if [ "${line:0:1}" == "#" ]
        then
            continue # ignore comments
        elif [ -z "$line" ]
        then
            continue # ignore empty lines
        fi
        sha1=$(echo "$line" | cut -d " " -f1 );version=$(echo "$line" | cut -d " " -f2)
        aVersions+=("$version");aSha1s+=("$sha1")
        # echo "loading sha1=$sha1 version=$version ..."
    done < "$versionfile"


    hash_found=$(sha1sum "$dotfile_path" | cut -d " " -f1)
    version_found=$(head -n 1 "$dotfile_path" | cut -d " " -f3)
    version_latest="${aVersions[${#aVersions[@]}-1]}"
    echo "[$dotfile] found $dotfile version=$version_found sha1=$hash_found"
    if [ "$version_found" == "$version_latest" ]
    then
        echo "[$dotfile] already latest verson."
        return
    fi
    for v in "${!aVersions[@]}"
    do
        if [ "$version_found" != "${aVersions[v]}" ]
        then
            continue
        fi
        # found version:
        if [ "$hash_found" == "${aSha1s[v]}" ]
        then
            echo "[$dotfile] outdated $dotfile version verified by sha1"
            echo "[$dotfile] updating..."
            cp "$dotfile" "$dotfile_path"
        else
            echo "[$dotfile] WARNING: not updating $dotfile custom version found"
            echo "[$dotfile] sha1 missmatch '$hash_found' != '${aSha1s[v]}'"
        fi
        return
    done
    echo "[$dotfile] WARNING: unkown version didn't update $dotfile"
}

function update_vim() {
    local rcpath
    rcpath="$HOME/.vimrc"
    if [ -f  "$rcpath" ]
    then
        check_dotfile_version vim vimrc "$rcpath"
        return
    fi
    echo "[vim] updating..."
    cp vimrc "$rcpath" || exit 1
}

function update_bash() {
    local rcpath
    rcpath="$HOME/.bashrc"
    if [ -f  "$rcpath" ]
    then
        check_dotfile_version bash bashrc "$rcpath"
        return
    fi
    echo "[bash] updating..."
    cp bashrc "$rcpath" || exit 1
}

function update_tmux() {
    local rcpath
    if [ ! -x "$(command -v tmux)" ]
    then
        install_tool tmux
    fi
    rcpath="$HOME/.tmux.conf"
    if [ -f  "$rcpath" ]
    then
        check_dotfile_version tmux tmux.conf "$rcpath"
        return
    fi
    echo "[tmux] updating..."
    cp tmux.conf "$rcpath" || exit 1
}

function update_irb() {
    local rcpath
    rcpath="$HOME/.irbrc"
    if [ -f  "$rcpath" ]
    then
        check_dotfile_version irb irbrc "$rcpath"
        return
    fi
    echo "[irb] updating..."
    cp irbrc "$rcpath" || exit 1
}

function update_bashprofile() {
    echo "[bash_profile] has to be done manually."
}

function update_teeworlds() {
    local cwd
    local twdir
    cwd="$(pwd)"
    if [[ "$OSTYPE" == "darwin"* ]]
    then
        twdir="/Users/$USER/Library/Application Support/Teeworlds"
    else
        twdir="/home/$USER/.teeworlds"
    fi
    mkdir -p "$twdir"
    cd "$twdir" || exit 1
    if [ ! -d GitSettings/ ]
    then
        git clone git@github.com:ChillerTW/GitSettings.git
    fi
    cd GitSettings || exit 1
    git pull
    cd "$twdir" || exit 1
    if [ ! -d maps ]
    then
        git clone git@github.com:ChillerTW/GitMaps.git maps
    fi
    cd "$twdir" || exit 1
    if [ -f settings_zilly.cfg ]
    then
        echo "exec GitSettings/zilly.cfg" > settings_zilly.cfg
    fi
    cd "$cwd" || exit 1
}

echo "Starting chiller configs setup script"
echo "This script replaces config files without backups."
echo "Data might be lost!"
echo "Do you really want to execute it? [y/N]"
read -rn 1 -p "" inp
echo ""
if [ "$inp" == "Y" ]; then
    test
elif [ "$inp" == "y" ]; then
    test
else
    echo "Stopped script."
    exit
fi

install_vim

update_vim
update_bash
update_tmux
update_irb
update_bashprofile
update_teeworlds


if [ "$is_vim_install" == "1" ]
then
    vim
    cwd="$(pwd)"
    cd ~/.vim/plugged/YouCompleteMe || exit 1
    python3 install.py
    cd "$cwd" || exit 1
fi

