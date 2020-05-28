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

  # here filter out time stamps appearing in the input
  textA=`cat $txtfile | perl -ne 'use open qw(:std :utf8); use utf8; chomp; if (!(m/^\s*\[.*\]\s*$/)) {printf("%s\n", $_);}'`

  textB=`echo "$testA" | perl $PERLdir/kickout_dangling_punctuation.perl`
  text=`echo "$textB" | perl $PERLdir/apostrophe2apostrophe.perl | perl $PERLdir/strip_off_punct_v4b.perl | perl $PERLdir/strip_off_CGN_marks.perl | perl -ne 'chomp; printf("%s\n", lc($_));'`

  echo $textA | perl -ne 'chomp; @tok=split(/\s+/); for ($i=0; $i <= $#tok; $i++) {printf("%s\n", $tok[$i]);}' > $workingdir/tmpA
  echo $text | perl -ne 'chomp; @tok=split(/\s+/); for ($i=0; $i <= $#tok; $i++) {printf("%s\n", $tok[$i]);}' > $workingdir/tmpB
  paste $workingdir/tmpA $workingdir/tmpB > $one2one_table
  
  LA=`cat $workingdir/tmpA | wc -l`
  LB=`cat $workingdir/tmpB | wc -l`
  if [[ $LA -ne $LB ]]; then
    echo mismatch length normalised/unnormalised texts in txt2tg >> $statusfile
  else
    echo match length normalised/unnormalised texts in txt2tg >> $statusfile
  fi

  rm $workingdir/tmpA $workingdir/tmpB

# no newline after or in $text
text=`echo -n $text | tr '\n' ' '`
  cat $mothertg | sed "s/__FILEDURATION__/$fileduration/" | sed "s/__FROM__/$from/" | sed "s/__TO__/$to/" | sed s/__TRANSCRIPTION__/"$text"/ > $tgfile

done

