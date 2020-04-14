#!/bin/bash

workingdir=$1

for tgfile in $(ls $workingdir/*tg); do

  txtfile=`echo $tgfile | sed 's/\.tg/.txt/'`
  
  # still unclear what to do here
  echo "$txtfile"

done

