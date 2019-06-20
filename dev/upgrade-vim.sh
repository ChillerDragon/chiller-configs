#!/bin/bash

# TODO:
# check git status and if it is clean git pull automatically
# if status is dirty cancle
# to make sure our versions are up to date

vf_vim="error"
rc_vim="error"
aVimVersions=();aVimSha1s=()

echo "!!! WARNING !!!"
echo "Only run this script if you know what you are doing!"
echo "Make sure to have a up to date vim_versions.txt"
echo "Always run git pull before executing this!"
echo ""
echo "This script looks at your ~/.vimrc and updates the vimrc in this repo"
echo ""
echo "usage: update your ~/.vimrc file BUT NOT THE VERSION and then run the script"
echo "the script updates the version and computes a sha1 and stores it in the repo"
read -p "Run the script? [y/N]" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "stopping..."
    exit 1
fi

if [ -f vim_versions.txt ]
then
    vf_vim=vim_versions.txt
elif [ -f dev/vim_versions.txt ]
then
    vf_vim=dev/vim_versions.txt
else
    echo "Error: vim_versions.txt not found"
    exit
fi

if [ -f vimrc ]
then
    rc_vim=vimrc
elif [ -f ../vimrc ]
then
    rc_vim=../vimrc
else
    echo "Error: vimrc not found"
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
    sha1=$(echo $line | cut -d " " -f1 );version=$(echo $line | cut -d " " -f2)
    aVimVersions+=("$version");aVimSha1s+=("$sha1")
    # echo "loading sha1=$sha1 version=$version ..."
done < "$vf_vim"

hash_found=$(sha1sum ~/.vimrc | cut -d " " -f1)
hash_latest="${aVimSha1s[-1]}"
version_found=$(head -n 1 ~/.vimrc | cut -d " " -f3)
version_latest="${aVimVersions[-1]}"
echo "found vimrc version=$version_found latest=$version_latest"
echo "found vimrc sha1=$hash_found latest=$hash_latest"
if [ "$version_found" != "$version_latest" ]
then
    echo "Error: version is not latest."
    exit
elif [ "$hash_found" == "$hash_latest" ]
then
    echo "Error: version is already up to date"
    exit
fi

version_updated=$((version_latest + 1))
version_updated=$(printf "%04d\n" "$version_updated")
echo "updating '$version_latest' -> '$version_updated' ..."

cp ~/.vimrc "$rc_vim"

vimrc_body=$(tail $rc_vim -n +2)
vimrc_header='" version '$version_updated

echo "$vimrc_header" > $rc_vim
echo "$vimrc_body" >> $rc_vim

hash_updated=$(sha1sum $rc_vim | cut -d " " -f1)
echo "updating '$hash_latest' -> '$hash_updated' ..."

echo "$hash_updated $version_updated" >> $vf_vim

cp "$rc_vim" ~/.vimrc # overwrite local vim with new version to not get a custom oudated version

echo "done."

