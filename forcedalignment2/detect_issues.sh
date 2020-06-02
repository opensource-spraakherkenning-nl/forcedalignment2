#!/bin/bash

wavdir=$1

# get rid of 16kHz files wth extension .wav
for wavfile in $(ls $wavdir/*16khz.wav 2> /dev/null); do
  mv $wavfile "$wavfile"_16khz
done

for wavfile in $(ls $wavdir/*wav); do
  tmp=`basename $wavfile`
  tmp2=`echo $tmp | sed 's/\.wav/-16khz/'`
  cat $wavdir/log/$tmp2/log/align.1.log | perl -e '$FN=$ARGV[0]; while (<STDIN>) {chomp; if (m/is\s+(.+)\s+over\s+([0-9]+)\s+frames/) { printf("%s: overall log likelihood/frame: %s (%s frames)\n", $FN, $1, $2)}}' $tmp 
done 

