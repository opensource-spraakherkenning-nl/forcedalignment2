#!/bin/env python3

#  phons2words.py
#
#
#  Created by Eleanor Chodroff on 2/07/16.

import sys
import glob


split_folder=sys.argv[1]
target_file=sys.argv[2]

pron_ali=open(target_file,'w', encoding="utf-8")
pron=[]
files = glob.glob(split_folder+'/*.txt')

# process each file
for filei in files:
#    print filei
    f = open(filei, 'r', encoding="utf-8")
    for line in f:
        line=line.split("\t")
        file=line[1]
        phon_pos=line[6]
        #print phon_pos
        if phon_pos == "SIL":
            phon_pos = "SIL_S"
        elif phon_pos == "sil":
            phon_pos = "sil_s"
        phon_pos=phon_pos.split("_")
        phon=phon_pos[0]
        pos=phon_pos[1]
        #print pos
        if pos == "B":
            start=line[9]
            pron.append(phon)
        if pos == "S":
            start=line[9]
            #end=line[10]
            end=str(float(line[9])+float(line[10])) + "\n"
            pron.append(phon)
            pron_ali.write(file + '\t' + ' '.join(pron) +'\t'+ str(start) + '\t' + str(end))
            pron=[]
        if pos == "E":
            end=str(float(line[9])+float(line[10])) + "\n"
            pron.append(phon)
            pron_ali.write(file + '\t' + ' '.join(pron) +'\t'+ str(start) + '\t' + str(end))
            pron=[]
        if pos == "I":
            pron.append(phon)
    f.close()
pron_ali.close()
