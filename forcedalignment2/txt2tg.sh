#!/bin/bash

workingdir=$1
scriptdir=$2
mothertg=$3

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

  textA=`cat $txtfile`
  text=`echo "$textA" | perl $scriptdir/perl/apostrophe2apostrophe.perl | perl $scriptdir/perl/strip_off_punct_v4b.perl | perl $scriptdir/perl/strip_off_CGN_marks.perl | perl -ne 'chomp; printf("%s\n", lc($_));'`

  echo $textA | perl -ne 'chomp; @tok=split(/\s+/); for ($i=0; $i <= $#tok; $i++) {printf("%s\n", $tok[$i]);}' > $workingdir/tmpA
  echo $text | perl -ne 'chomp; @tok=split(/\s+/); for ($i=0; $i <= $#tok; $i++) {printf("%s\n", $tok[$i]);}' > $workingdir/tmpB
  paste $workingdir/tmpA $workingdir/tmpB > $one2one_table
  rm $workingdir/tmpA $workingdir/tmpB

# no newline after $text
text=`echo -n $text`
  cat $mothertg | sed "s/__FILEDURATION__/$fileduration/" | sed "s/__FROM__/$from/" | sed "s/__TO__/$to/" | sed s/__TRANSCRIPTION__/"$text"/ > $tgfile

done

