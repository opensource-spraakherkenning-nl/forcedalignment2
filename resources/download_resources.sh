#!/bin/bash

# this scripts build the resource tarball when the resources file are presented
# in the directory structure (but untracked by git)

if [ "$1" != "--force" ]; then
    GITROOT=$(git rev-parse --show-toplevel)
    if [ -z "$GITROOT" ]; then
        echo "not in a git repository!"
        exit 2
    fi

    cd $GITROOT/resources
fi

rm forcedalignmentFA3_resources.tar.gz 2>/dev/null
wget https://applejack.science.ru.nl/downloads/forcedalignment/forcedalignmentFA3_resources.tar.gz && tar -xvzf forcedalignmentFA3_resources.tar.gz
echo $?
