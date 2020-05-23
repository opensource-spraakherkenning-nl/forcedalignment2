#!/bin/bash

workingdir=$1
scriptdir=$2

for alifile in $(ls $workingdir/*aliphw2); do

  ctmfile=`echo $alifile | sed 's/\.aliphw2/.ctm/'`
  basename=`basename $alifile`
  audiofn=`echo $basename | sed 's/\.aliphw2//'`
  cat $alifile | perl $scriptdir/perl/ali2word_ctm.perl $audiofn > $ctmfile

done

