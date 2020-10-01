#!/bin/bash

workingdir=$1
backgroundlexicon=$2
#/home/ltenbosch/clst-asr-fa/lexicon_from_MARIO.txt
OOVlexout=$3
scratchdir=$4
PERLdir=$5
KALDIbin=$6
G2PFSTfile=$7

rm -rf $OOVlexout
touch $OOVlexout

# using phonetisaurus
#KALDIbin was /vol/tensusers2/eyilmaz/local/bin
#export PATH=$KALDIbin:$PATH # use of KALDIbin export to be avoided in webservice
echo phonetisaurus PATH in g2p.sh IMPORTANT

rm -f $scratchdir/OOVwordlist.txt
for tgfile in $(ls $workingdir/*.tg); do

  cat $tgfile | tail -1 | perl -ne 'use open qw(:std :utf8); use utf8; chomp; s/^\s*text\s+=\s+\"//; s/\"\s*$//; printf("%s\n", $_);' | perl $PERLdir/spotOOV.perl $backgroundlexicon | grep 0 | sort -u | awk '{print $1}' >> $scratchdir/OOVwordlist.txt

done

cat $scratchdir/OOVwordlist.txt | sort | uniq > $scratchdir/OOVwordlist_sorted.txt
#phonetisaurus-apply --model /home/ltenbosch/KALDI_g2p/train_dutch/model.fst --word_list $scratchdir/OOVwordlist_sorted.txt -n 1 > $OOVlexout
phonetisaurus-apply --model $G2PFSTfile --word_list $scratchdir/OOVwordlist_sorted.txt -n 1 > $OOVlexout || exit 2


rm $scratchdir/OOVwordlist_sorted.txt $scratchdir/OOVwordlist.txt


