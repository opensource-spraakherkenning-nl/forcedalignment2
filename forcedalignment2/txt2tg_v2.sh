#!/bin/bash

workingdir=$1
PERLdir=$2
mothertg=$3
statusfile=$4

for txtfile in $(ls $workingdir/*txt); do

  wavfile=`echo $txtfile | sed 's/\.txt/.wav/'`
  tgfile=`echo $txtfile | sed 's/\.txt/.tg/'`
  one2one_table=`echo $txtfile | sed 's/\.txt/.one2one_table/'`

  if [[ -f "$wavfile" ]]; then
    fileduration=`sox $wavfile -n stat 2>&1 | grep Length | awk '{print $3}'`
    from=0
    to=$fileduration
    Nch=`sox --i $wavein | grep Channels | awk '{print $3}'`
  else
    fileduration=1
    from=0
    to=1
  fi

#  cat $txtfile  | perl /home/tenbosch/perl//txt2one2one_table.perl > $one2one_table
  cat $txtfile  | perl $PERLdir/txt2one2one_table.perl > $one2one_table
  echo txt2one2one_table >> $statusfile


  text=`cat $one2one_table | perl -ne 'chomp; @tok = split(/\t/); printf("%s ", $tok[1])'`

# no newline after or in $text
text=`echo -n $text | tr '\n' ' '`
  cat $mothertg | sed "s/__FILEDURATION__/$fileduration/" | sed "s/__FROM__/$from/" | sed "s/__TO__/$to/" | sed s/__TRANSCRIPTION__/"$text"/ > $tgfile

done

