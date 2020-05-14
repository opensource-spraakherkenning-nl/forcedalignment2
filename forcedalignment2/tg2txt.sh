#!/bin/bash

workingdir=$1
pldir=$2

for tgfile in $(ls $workingdir/*tg); do

  txtfile=`echo $tgfile | sed 's/\.tg/.txt/'`
  
  # still unclear what to do here
  cat "$tgfile" | perl $pldir/tg2txt.pl > $txtfile 

done

