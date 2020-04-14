#!/bin/bash

workingdir=$1
alltar=$2

cd $workingdir

rm -f "$alltar"
tar cvf "$alltar" *aliphw2

cd -


