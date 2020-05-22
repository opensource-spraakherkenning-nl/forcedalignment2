#!/bin/bash

workingdir=$1
scriptdir=$2

for alifile in $(ls $workingdir/*aliphw2); do

  tgfile=`echo $alifile | sed 's/\.aliphw2/_out.tg/'`
  cat $alifile | $scriptdir/perl/ali2tg_v2.perl > $tgfile

done

