#!/bin/bash

workingdir=$1


for tgfile in $(ls $workingdir/*tg); do

  txtfile=`echo $tgfile | sed 's/\.tg/.txt/g'`
  wavfile=`echo $tgfile | sed 's/\.tg/.wav/g'`

  test1=`cat $tgfile | tail -1 | perl -ne 'chomp; m/\"(.*)\"\s*$/; $txt = $1; $txt =~ s/^\s+//g; $txt =~ s/\s+$//g; printf("%s\n", length($txt));'`


  if [  0 -lt $test1 ]; then
    echo OK > /dev/null
  else
    mv $tgfile "$tgfile"_
    mv $txtfile "$txtfile"_
    mv $wavfile "$wavfile"_
    basenm=`basename $tgfile`
    echo $basenm removed empty tg
  fi

done

