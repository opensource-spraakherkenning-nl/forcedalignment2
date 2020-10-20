#1/bin/bash

if [ -d resources ]; then
    RESOURCEDIR=$(realpath resources)
else
    echo "Run this script from the root directory of the forcedalignment2 repository">&2
    exit 2
fi


WEBSERVICEDIR=$(realpath forcedalignment2)
WORKDIR=$(mktemp -d)
if [ -z "$WORKDIR" ]; then
    echo "Unable to create workdir">&2
    exit 2
fi

mkdir $WORKDIR/input
cp resources/data/test/* $WORKDIR/input/
mkdir $WORKDIR/output
mkdir $WORKDIR/scratch

$WEBSERVICEDIR/wrapper.sh $WORKDIR/input $WORKDIR/scratch $RESOURCEDIR $WORKDIR/output $WEBSERVICEDIR $WORKDIR/status.log

echo "(all output is in $WORKDIR)">&2
