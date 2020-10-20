#!/bin/bash

# this scripts build the resource tarball when the resources file are presented
# in the directory structure (but untracked by git)

GITROOT=$(git rev-parse --show-toplevel)
if [ -z "$GITROOT" ]; then
    echo "not in a git repository!"
    exit 2
fi

cd $GITROOT/resources

tar -cvzf forcedalignment2_resources.tar.gz lexicons data/local/dict_osnl/lexicon.txt G2PFST/ data/local/lang/
echo $?
