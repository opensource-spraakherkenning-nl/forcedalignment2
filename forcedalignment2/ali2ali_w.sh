#!/bin/bash

workingdir=$1

for alifile in $(ls $workingdir/*ali); do
  one2one_table=`echo $alifile | sed 's/\.ali/.one2one_table/'`
  aliphw2file=`echo $alifile | sed 's/\.ali/.aliphw2/'`

  # text
  text=`cat $one2one_table | awk '{print $1}' | perl -e 'while (<STDIN>) {chomp; push(@array, $_);} printf("%s", join(" ", @array));'`

  cat $alifile | perl -e '$text=$ARGV[0]; @words = split(/\s+/, $text); $wordid = 0; while(<STDIN>) {chomp; @tok = split(/\s+/); $otherwise = 1; if ($tok[6] =~ m/_B/) {$otherwise = 0; $word = $words[$wordid]; $wordid++; $tok[6] =~ s/_.*$//g; printf("%s\t%s\t%s\t%s\n", $tok[4], $tok[5], $tok[6], $word)} if ($tok[6] =~ m/_S/) {$otherwise = 0; $word = $words[$wordid]; $wordid++; $tok[6] =~ s/_.*$//g; printf("%s\t%s\t%s\t??%s\n", $tok[4], $tok[5], $tok[6], $word)} if ($otherwise) {$tok[6] =~ s/_.*$//g; printf("%s\t%s\t%s\n", $tok[4], $tok[5], $tok[6])}}' "$text" > $aliphw2file
done

