#!/bin/bash

workingdir=$1
PERLdir=$2

for alifile in $(ls $workingdir/*aliphw2); do

  tg2file=`echo $alifile | sed 's/\.aliphw2/.out.tg2/'`
  tgfile=`echo $alifile | sed 's/\.aliphw2/.out.tg/'`
  cat $alifile | perl $PERLdir/ali2tg_v2.perl > $tg2file
  cat $tg2file | perl -ne 'chomp; if (m/text\s+=/) {s/\[.*\]_//; printf("%s\n",  $_);} else {printf("%s\n", $_)}' > $tgfile
done

