#!/bin/bash

workingdir=$1


for txtfile in $(ls $workingdir/*txt); do

  wavfile=`echo $txtfile | sed 's/\.txt/.wav/'`

  test1=`file $txtfile | egrep 'ASCII|UTF' | wc -l`

  
  if [ 0 -lt  $test1 ] ; then
    echo OK > /dev/null
  else
    mv $wavfile "$wavfile"_
    mv $txtfile "$txtfile"_
    basenm=`basename $txtfile`
    echo $basenm removed non ASCII UTF
  fi

done



for wavfile in $(ls $workingdir/*wav); do

  txtfile=`echo $wavfile | sed 's/\.wav/.txt/'`
  test=`sox --info $wavfile 2>&1 | grep Channels | wc -l`
  
  if [ 0 -lt $test ]; then
    echo OK > /dev/null
  else
    mv $wavfile "$wavfile"_
    mv $txtfile "$txtfile"_
    basenm=`basename $wavfile`
    echo $basenm removed non wav
  fi

done

