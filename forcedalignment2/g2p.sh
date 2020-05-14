#!/bin/bash

workingdir=$1
backgroundlexicon=$2
#/home/ltenbosch/clst-asr-fa/lexicon_from_MARIO.txt
OOVlexout=$3
scratchdir=$4
scriptdir=$5
KALDIbin=$6
G2PFSTfile=$7

rm -rf $OOVlexout
touch $OOVlexout

# using phonetisaurus
#KALDIbin was /vol/tensusers2/eyilmaz/local/bin
## export PATH=$KALDIbin:$PATH # use of KALDIbin should be avoided in service
echo phonetisaurus PATH in g2p.sh ?

for txtfile in $(ls $workingdir/*txt); do

  cat $txtfile | perl -ne 'chomp; @tok=split(/\s+/); for ($i = 0; $i <= $#tok; $i++) {printf("%s\n", $tok[$i]);}' | perl $scriptdir/perl/apostrophe2apostrophe.perl | perl $scriptdir/perl/strip_off_punct_v4b.perl | perl $scriptdir/perl/strip_off_CGN_marks.perl | perl -ne 'chomp; printf("%s\n", lc($_));' | perl $scriptdir/perl/spotOOV.perl $backgroundlexicon | grep 0 | sort -u | awk '{print $1}' >> $scratchdir/OOVwordlist.txt

done

cat $scratchdir/OOVwordlist.txt | sort | uniq > $scratchdir/OOVwordlist_sorted.txt
#phonetisaurus-apply --model /home/ltenbosch/KALDI_g2p/train_dutch/model.fst --word_list $scratchdir/OOVwordlist_sorted.txt -n 1 > $OOVlexout
phonetisaurus-apply --model $G2PFSTfile --word_list $scratchdir/OOVwordlist_sorted.txt -n 1 > $OOVlexout


rm $scratchdir/OOVwordlist_sorted.txt $scratchdir/OOVwordlist.txt


