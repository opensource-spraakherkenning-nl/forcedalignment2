#1/bin/bash
if [ -z "$KALDI_ROOT" ]; then
    echo "\$KALDI_ROOT must be set prior to running the test (are you in a LaMachine environment with kaldi?)">&2
    exit 2
fi

if [ -d resources ]; then
    RESOURCEDIR=$(realpath resources)
else
    echo "Run this script from the root directory of the forcedalignment2 repository">&2
    exit 2
fi

if [ ! -f resources/lexicons/lexicon_from_MARIO.txt ]; then
    cd resources
    ./download_resources.sh || exit 2
    cd ..
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
r=$?

echo "(all output is in $WORKDIR)">&2
exit $r
