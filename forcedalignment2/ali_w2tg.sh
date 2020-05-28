#!/bin/bash

workingdir=$1
PERLdir=$2

for alifile in $(ls $workingdir/*aliphw2); do

  tgfile=`echo $alifile | sed 's/\.aliphw2/.out.tg/'`
  cat $alifile | perl $PERLdir/ali2tg_v2.perl > $tgfile

done
