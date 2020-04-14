#!/bin/bash

tar=$1
targetdir=$2
scratchdir=$3

mkdir $scratchdir/tmp123
rm -rf $scratchdir/tmp123/*
cp $1 $scratchdir/tmp123

cd $scratchdir/tmp123
tar xvf $1

if [ ! -d $targetdir ]; then
  mkdir $targetdir
fi

wavs=`find . -name \*wav`
if [[ "$wavs" != "" ]]; then
  cp $wavs $targetdir
fi
tgs=`find . -name \*tg`
if [[ "$tgs" != "" ]]; then
  cp $tgs $targetdir
fi
txts=`find . -name \*txt`
if [[ "$txts" != "" ]]; then
  cp $txts $targetdir
fi
cd -
rm -rf tmp



