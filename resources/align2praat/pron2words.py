#!/usr/bin/python
# -*- coding: utf-8 -*-
#
#  phons2words.py
#
#
#  Created by Eleanor Chodroff on 2/07/16.



#### issues with unicode (u'')
import sys,csv,os,os.path,re,codecs,pdb

lexicon=sys.argv[1]
pron_file=sys.argv[2]
wordali_file=sys.argv[3] 


# make dictionary of word: prons
def getLexicon(file):
    with codecs.open(os.path.join(lexicon,file,"dict","lexicon.txt"), "rb", "utf-8") as f:
        for line in f:
            line = line.strip()
            columns = line.split("\t")
            word = columns[0]
            pron = columns[1]
            #print pron
            try:
                lex[pron].append(word)
            except:
                lex[pron] = list()
                lex[pron].append(word)
    return lex

# open file to write

word_ali = codecs.open(wordali_file, "wb+", "utf-8")
# Write columne headers (createTextGrid_word.praat expects a column header line)
word_ali.write("file\tword\tstart\tend\n")

file = ""
lex={}
# read file with most information in it
with codecs.open(pron_file, "rb", "utf-8") as f:
    for line in f:
        line = line.strip()
        line = line.split("\t")
        # get the pronunciation
        pron = line[1]
        # look up the word from the pronunciation in the dictionary
        if file != line[0]:
            lex = getLexicon(line[0])
        word = lex.get(pron)
        word = word[0]
        file = line[0]
        start = line[2]
        end = line[3]
        word_ali.write(file + '\t' + word + '\t' + start + '\t' + end + '\n')

word_ali.close()
