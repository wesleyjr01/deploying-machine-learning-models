#!/bin/bash

# Building packages and uploading them to a Gemfury repository

GEMFURY_URL=$PIP_EXTRA_INDEX_URL

# Termina o script de executar se der qualquer erro, de qualquer comando.
set -e

DIRS="$@"
BASE_DIR=$(pwd)
SETUP="setup.py"

warn() {
    echo "$@" 1>&2
}

die() {
    warn "$@"
    exit 1
}

build() {
    # tirando a ultima barra de DIR
    DIR="${1/%\//}"
    echo "Checking directory $DIR"
    cd "$BASE_DIR/$DIR"
    # -e checka a existencia de arquivo
    # da pra refatorar e por um if
    # [ ! -e $SETUP ] && warn "No $SETUP file, skipping" && return
    if [ ! -e $SETUP ]; then
        warn "No $SETUP file, skipping"
        return
    fi
    PACKAGE_NAME=$(python $SETUP --fullname)
    echo "Package $PACKAGE_NAME"
    python "$SETUP" sdist bdist_wheel || die "Building package $PACKAGE_NAME failed"
    for X in $(ls dist)
    do
        curl -F package=@"dist/$X" "$GEMFURY_URL" || die "Uploading package $PACKAGE_NAME failed on file dist/$X"
    done
}

if [ -n "$DIRS" ]; then
    for dir in $DIRS; do
        build $dir
    done
else
    ls -d */ | while read dir; do
        build $dir
    done
fi