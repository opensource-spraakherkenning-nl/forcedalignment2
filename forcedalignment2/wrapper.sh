#!/bin/bash

# sequence of bash scripts opering on files in a certain directory
# X.wav + X.txt or X.wav + X.tg or .tar
# optional: .lexaddon # not now

## call from above: $WEBSERVICEDIR/wrapper.sh $INPUTDIRECTORY $SCRATCHDIRECTORY $RESOURCESDIRECTORY $OUTPUTDIRECTORY

# the following is probably not necessary, can be dealt with using CLAM input mechanisms
#for tarfile in $(ls $INPUTDIRECTORY/*tar); do
#  ./extract_tar.sh $tarfile $SCRATCHDIRECTORY/new
#done
# puts all content of tar flattened in subdir new

# for the moment: no time stamps yet

#INPUTDIRECTORY=$1
#SCRATCHDIRECTORY=$2
#RESOURCESDIRECTORY=$3
#OUTPUTDIRECTORY=$4

# put everything in /vol/tensusers/ltenbosch/webservices/KALDI/resources2

INPUTDIRECTORY=/vol/tensusers/ltenbosch/FA_webservice_in
SCRATCHDIRECTORY=/tmp
backgroundlexicon=/home/ltenbosch/clst-asr-fa/lexicon_from_MARIO.txt
RESOURCESDIRECTORY=/vol/tensusers/ltenbosch/clst-asr_forced-aligner/kaldi/egs/clst-asr_forced-aligner/s5
OUTPUTDIRECTORY=$INPUTDIRECTORY

configfile=/home/ltenbosch/clst-asr-fa/align_config.rc
scriptdir=/home/ltenbosch
mothertg=/home/ltenbosch/KALDI_FA_Mario/MOTHER.tg
KALDIbin=/vol/tensusers2/eyilmaz/local/bin
G2PFSTfile=/home/ltenbosch/KALDI_g2p/train_dutch/model.fst

dos2unix $INPUTDIRECTORY/*txt
dos2unix $INPUTDIRECTORY/*tg


./tg2txt.sh $INPUTDIRECTORY
# X.tg -> X.txt

./txt2tg.sh $INPUTDIRECTORY $scriptdir $mothertg
# writes X.txt to X.tg for all X -- also creates X.one2one_table. Assumes all wav.X available.

OOVlexout=$INPUTDIRECTORY/OOVlex.out
./g2p.sh $INPUTDIRECTORY $backgroundlexicon $OOVlexout $SCRATCHDIRECTORY $scriptdir $KALDIbin $G2PFSTfile
#detect oovs in all X.txt
#apply p-saurus

foregroundlexicon=$INPUTDIRECTORY/foregroundlexicon.lex
cat $backgroundlexicon $OOVlexout > $foregroundlexicon

pSPN=0.05
pSIL=0.05
./wav_tg2ali.sh $configfile $INPUTDIRECTORY $pSPN $pSIL $foregroundlexicon $RESOURCESDIRECTORY
# X.wav + X.tg -> $INPUTDIRECTORY/log/final_ali.txt

./finalali2ali.sh $INPUTDIRECTORY/log/final_ali.txt $INPUTDIRECTORY
# final_ali.txt -> X.ali

./ali2ali_w.sh $INPUTDIRECTORY
# X.ali + X.one2one_table -> X.aliphw2

./ali_w2tar.sh $INPUTDIRECTORY all.tar
# all X.ali_phw2 into all.tar




