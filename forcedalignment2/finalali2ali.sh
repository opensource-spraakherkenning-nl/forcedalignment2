#!/bin/bash

finalali=$1
wavdir=$2

# get rid of 16kHz files wth extension .wav
for wavfile in $(ls $wavdir/*16khz.wav 2> /dev/null); do
  mv $wavfile "$wavfile"_16khz
done

for wavfile in $(ls $wavdir/*wav); do
  aliout=`echo $wavfile | sed 's/\.wav/.ali/'`
  tmp=`basename $wavfile`
  tmp2=`echo $tmp | sed 's/\.wav/-16khz/'`
  cat $finalali | perl -e '$key=$ARGV[0]; while (<STDIN>) {chomp; @tok=split(/\s+/); if (($. == 1) | ($tok[0] eq $key)) {printf("%s\n", $_);}}' $tmp2 > $aliout
done 

