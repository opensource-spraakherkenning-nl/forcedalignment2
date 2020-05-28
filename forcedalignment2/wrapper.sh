#!/bin/bash

# sequence of bash scripts opering on files in a certain directory
# X.wav + X.txt or X.wav + X.tg or .tar
# optional: .lexaddon # not now

## call from above: $WEBSERVICEDIR/wrapper.sh $INPUTDIRECTORY $SCRATCHDIRECTORY $RESOURCESDIRECTORY $OUTPUTDIRECTORY $STATUSFILE

# the following is probably not necessary, can be dealt with using CLAM input mechanisms
#for tarfile in $(ls $INPUTDIRECTORY/*tar); do
#  ./extract_tar.sh $tarfile $SCRATCHDIRECTORY/new
#done
# puts all content of tar flattened in subdir new

# for the moment: no time stamps yet

INPUTDIRECTORY=$1
SCRATCHDIRECTORY=$2
RESOURCESDIRECTORY=$3
OUTPUTDIRECTORY=$4
WEBSERVICEDIRECTORY=$5
STATUSFILE=$6


echo input dir $INPUTDIRECTORY
echo scratch dir $SCRATCHDIRECTORY
echo resources dir $RESOURCESDIRECTORY
echo output dir $OUTPUTDIRECTORY
echo webservice dir $WEBSERVICEDIRECTORY
echo statusfile $STATUSFILE

# put everything in /vol/tensusers/ltenbosch/webservices/KALDI/resources2

#INPUTDIRECTORY=/vol/tensusers/ltenbosch/FA_webservice_in
#SCRATCHDIRECTORY=/tmp
##RESOURCESDIRECTORY=/vol/tensusers/ltenbosch/clst-asr_forced-aligner/kaldi/egs/clst-asr_forced-aligner/s5
#RESOURCESDIRECTORY=/vol/tensusers/ltenbosch/webservices/KALDI/resources2

#OUTPUTDIRECTORY=$INPUTDIRECTORY


#backgroundlexicon=/home/ltenbosch/clst-asr-fa/lexicon_from_MARIO.txt
#configfile=/home/ltenbosch/clst-asr-fa/align_config.rc
#scriptdir=/home/ltenbosch
#mothertg=/home/ltenbosch/KALDI_FA_Mario/MOTHER.tg
#KALDIbin=/vol/tensusers2/eyilmaz/local/bin
#G2PFSTfile=/home/ltenbosch/KALDI_g2p/train_dutch/model.fst

backgroundlexicon=$RESOURCESDIRECTORY/lexicons/lexicon_from_MARIO.txt
configfile=$RESOURCESDIRECTORY/config/align_config.rc
scriptdir=$RESOURCESDIRECTORY
mothertg=$RESOURCESDIRECTORY/textgrids/MOTHER.tg
KALDIbin=__not_used__ # $RESOURCESDIRECTORY/KALDIbin
G2PFSTfile=$RESOURCESDIRECTORY/G2PFST/Dutch/model.fst
KALDIbin2=__not_used__ # $RESOURCESDIRECTORY/KALDIbin2 # only for ali-to-phones

PLDIR=$RESOURCESDIRECTORY/perl

cd $WEBSERVICEDIRECTORY

# ???
#dos2unix $INPUTDIRECTORY/*txt
#dos2unix $INPUTDIRECTORY/*tg

echo dos2unix >> $STATUSFILE

#./tg2txt.sh $INPUTDIRECTORY $PLDIR
# X.tg -> X.txt
#echo tg2txt >> $STATUSFILE

#echo een twee drie > $INPUTDIRECTORY/file1.txt
#this was a debug repair

./txt2tg.sh $INPUTDIRECTORY $PLDIR $mothertg $STATUSFILE
# writes X.txt to X.tg for all X -- does normalisation. Also creates X.one2one_table. Assumes all wav.X available.

echo txt2tg >> $STATUSFILE

## KALDIbin=/vol/tensusers2/eyilmaz/local/bin # kick this line out if in webservice
OOVlexout=$INPUTDIRECTORY/LEX.out.oov
./g2p.sh $INPUTDIRECTORY $backgroundlexicon $OOVlexout $SCRATCHDIRECTORY $PLDIR $KALDIbin $G2PFSTfile
#detect oovs in all X.txt after normalisation
#apply p-saurus

echo g2p >> $STATUSFILE

### add *.oov to lexicon if file exists
expandedlexicon=$INPUTDIRECTORY/expandedlexicon.lex
cat $backgroundlexicon > $expandedlexicon
for UserOov in $INPUTDIRECTORY/*.oov ; do
  cat $UserOov >> $expandedlexicon
  echo user oov $UserOov added to lexicon >> $STATUSFILE
done


foregroundlexicon=$INPUTDIRECTORY/foregroundlexicon.lex
cat $expandedlexicon $OOVlexout | sort -u > $foregroundlexicon

pSPN=0.05
pSIL=0.05
./wav_tg2ali.sh $configfile $INPUTDIRECTORY $pSPN $pSIL $foregroundlexicon $RESOURCESDIRECTORY $KALDIbin2 $STATUSFILE
# X.wav + X.tg -> $INPUTDIRECTORY/log/final_ali.txt

echo wav_tg2ali >> $STATUSFILE

./finalali2ali.sh $INPUTDIRECTORY/log/final_ali.txt $INPUTDIRECTORY
# final_ali.txt -> X.ali

echo finalali2ali >> $STATUSFILE

./ali2ali_w.sh $INPUTDIRECTORY
# X.ali + X.one2one_table -> X.aliphw2

echo ali2ali_w >> $STATUSFILE

# post processing transformations

#./ali_w2ctm.sh using ali2word_ctm.perl $audiofilename
#./ali_w2tg.sh using ali2tg_v2.perl

./ali_w2ctm.sh $INPUTDIRECTORY $PLDIR
# X.aliphw2 -> X.ctm # on wordlevel, requires name audiofile

echo ali_w2ctm >> $STATUSFILE

./ali_w2tg.sh $INPUTDIRECTORY $PLDIR
#X.aliphw2 -> X_out.tg

echo ali_w2tg >> $STATUSFILE

#./ali_w2tar.sh $INPUTDIRECTORY $INPUTDIRECTORY/all.tar
# all X.ali_phw2 into all.tar

#echo ali_w2tar >> $STATUSFILE

./result2outputdir.sh $INPUTDIRECTORY $OUTPUTDIRECTORY

echo result2outputdir >> $STATUSFILE

cd -

