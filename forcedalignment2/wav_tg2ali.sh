#!/bin/bash

configfile=$1
# is /home/ltenbosch/clst-asr-fa/align_config.rc

echo entering wav_tg2ali

wavdir=$2
pSPN=$3
pSIL=$4
FAlexicon=$5
RESOURCESDIRECTORY=$6
KALDIbin2=$7 # should not be necessary - unused
STATUSFILE=$8

die() {
    echo "-------------- fatal error ----------------" >&2
    echo "$1" >&2
    echo "-------------------------------------------" >&2
    exit 2
}

### ugly cd here
#cd /vol/tensusers/ltenbosch/clst-asr_forced-aligner/kaldi/egs/clst-asr_forced-aligner/s5
cd $RESOURCESDIRECTORY
# ./run_forced_alignment_v1.6_noBNF.sh --config ~/clst-asr-fa/align_config.rc /vol/tensusers/ltenbosch/KALDI_FA_in
#pSPN=0.05
#pSIL=0.05

echo now in directory `pwd`

#./run_forced_alignment_v1.8_noBNF.sh --config ~/clst-asr-fa/align_config.rc /vol/tensusers/ltenbosch/KALDI_FA_in $pSPN $pSIL $backgroundlexicon
./run_forced_alignment.sh --config $configfile $wavdir $pSPN $pSIL $FAlexicon $KALDIbin2 $STATUSFILE || die "forced alignment failed"

cd -


