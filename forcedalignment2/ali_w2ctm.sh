#!/bin/bash

workingdir=$1
PERLdir=$2

# assumed here channel = 1 for all files
channel=1
for alifile in $(ls $workingdir/*aliphw2); do

  ctm2file=`echo $alifile | sed 's/\.aliphw2/.ctm2/'`
  ctmfile=`echo $alifile | sed 's/\.aliphw2/.ctm/'`

  basename=`basename $alifile`
  audiofn=`echo $basename | sed 's/\.aliphw2//'`
  cat $alifile | perl $PERLdir/ali2word_ctm.perl $audiofn $channel > $ctm2file

  cat $ctm2file | perl -ne 'chomp; @tok = split(/\t/); $tok[4] =~ s/\[.*\]_//g; printf("%s\n", join("\t", @tok));' > $ctmfile

done

