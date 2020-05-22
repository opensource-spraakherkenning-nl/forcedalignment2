#!/bin/bash

indir=$1
outdir=$2


for file in $(ls $indir/*ali); do
  cp $file $outdir
done

for file in $(ls $indir/*aliphw2); do
cp $file $outdir
done

for file in $(ls $indir/*one2one_table); do
  cp $file $outdir
done

for file in $(ls $indir/*tg); do
  cp $file $outdir
done

for file in $(ls $indir/*ctm); do
  cp $file $outdir
done

for file in $(ls $indir/OOVlex*); do
  cp $file $outdir
done




