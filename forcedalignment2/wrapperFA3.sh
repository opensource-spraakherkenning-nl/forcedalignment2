#!/bin/bash

# sequence of bash scripts opering on files in a certain directory
# X.wav + X.txt or X.wav + X.tg or .tar
# optional: .lexaddon # not now

## call from above: $WEBSERVICEDIR/wrapper.sh $INPUTDIRECTORY $SCRATCHDIRECTORY $RESOURCESDIRECTORY $OUTPUTDIRECTORY $STATUSFILE

# the following is probably not necessary, can be dealt with using CLAM input mechanisms
#for tarfile in $(ls $INPUTDIRECTORY/*tar); do
#  ./extract_tar.sh $tarfile $SCRATCHDIRECTORY/new
#done
# puts all content of tar flattened in subdir new

# for the moment: no time stamps yet

INPUTDIRECTORY=$1
SCRATCHDIRECTORY=$2
RESOURCESDIRECTORY=$3
OUTPUTDIRECTORY=$4
WEBSERVICEDIRECTORY=$5
STATUSFILE=$6

echo input dir $INPUTDIRECTORY >&2
echo scratch dir $SCRATCHDIRECTORY >&2
echo resources dir $RESOURCESDIRECTORY >&2
echo output dir $OUTPUTDIRECTORY >&2
echo webservice dir $WEBSERVICEDIRECTORY >&2
echo statusfile $STATUSFILE >&2

# put everything in /vol/tensusers/ltenbosch/webservices/KALDI/resources2

#INPUTDIRECTORY=/vol/tensusers/ltenbosch/FA_webservice_in
if [ -z "$SCRATCHDIRECTORY" ]; then
    echo "Falling back to /tmp as scratch directory! This is sub-optimal and can lead to concurrency problems!" >&2
    SCRATCHDIRECTORY=/tmp
fi


die() {
    echo "-------------- fatal error ----------------" >&2
    echo "$1" >&2
    echo "-------------------------------------------" >&2
    exit 2
}

mkdir -p $SCRATCHDIRECTORY || die "unable to make scratch directory $SCRATCHDIRECTORY"

##RESOURCESDIRECTORY=/vol/tensusers/ltenbosch/clst-asr_forced-aligner/kaldi/egs/clst-asr_forced-aligner/s5
#RESOURCESDIRECTORY=/vol/tensusers/ltenbosch/webservices/KALDI/resources2

#OUTPUTDIRECTORY=$INPUTDIRECTORY


#backgroundlexicon=/home/ltenbosch/clst-asr-fa/lexicon_from_MARIO.txt
#configfile=/home/ltenbosch/clst-asr-fa/align_config.rc
#scriptdir=/home/ltenbosch
#mothertg=/home/ltenbosch/KALDI_FA_Mario/MOTHER.tg
#KALDIbin=/vol/tensusers2/eyilmaz/local/bin
#G2PFSTfile=/home/ltenbosch/KALDI_g2p/train_dutch/model.fst

#backgroundlexicon=$RESOURCESDIRECTORY/lexicons/lexicon_from_MARIO.txt
backgroundlexicon=$RESOURCESDIRECTORY/lexicons/lexicon.txt
configfile=$RESOURCESDIRECTORY/config/align_config.rc
scriptdir=$RESOURCESDIRECTORY
mothertg=$RESOURCESDIRECTORY/textgrids/MOTHER.tg
KALDIbin=__not_used__ # $RESOURCESDIRECTORY/KALDIbin
G2PFSTfile=$RESOURCESDIRECTORY/G2PFST/Dutch/model.fst
KALDIbin2=__not_used__ # $RESOURCESDIRECTORY/KALDIbin2 # only for ali-to-phones

PLDIR=$RESOURCESDIRECTORY/perl

cd $WEBSERVICEDIRECTORY || die "Webservicedirectory $WEBSERVICEDIRECTORY does not exist"

# ???
if ! which dos2unix; then
    die "dos2unix not found"
fi
dos2unix $INPUTDIRECTORY/*txt 2> /dev/null
dos2unix $INPUTDIRECTORY/*tg 2> /dev/null

echo dos2unix >> $STATUSFILE

#./tg2txt.sh $INPUTDIRECTORY $PLDIR
# X.tg -> X.txt
#echo tg2txt >> $STATUSFILE

#echo een twee drie > $INPUTDIRECTORY/file1.txt
#this was a debug repair

# ./txt2tg.sh $INPUTDIRECTORY $PLDIR $mothertg $STATUSFILE || die "txt2tg failed"
# writes X.txt to X.tg for all X -- does normalisation. Also creates X.one2one_table. Assumes all X.wav available.
./txt2tg_v2.sh $INPUTDIRECTORY $PLDIR $mothertg $STATUSFILE || die "txt2tg failed"

echo txt2tg >> $STATUSFILE


./check_tg.sh $INPUTDIRECTORY || die "check_tg failed"

echo check_tg >> $STATUSFILE



### add user *.dict to lexicon if file(s) exist
expandedlexicon=$INPUTDIRECTORY/expandedlexicon.lex
cat $backgroundlexicon > $expandedlexicon || die "unable to write expanded lexicon"
for UserOov in $(ls $INPUTDIRECTORY/*.dict 2> /dev/null); do
  # cat $UserOov | perl -ne 'use open qw(:std :utf8); use utf8; chomp; @tok = split(/\s+/); printf("%s\t%s\n", $tok[0], join(" ", @tok[1..$#tok]));' >> $expandedlexicon
  cat $UserOov | perl $PLDIR/merge_dict_v2.perl $expandedlexicon > $SCRATCHDIRECTORY/tmp1.txt || die "merge_dict failed"
  cp $SCRATCHDIRECTORY/tmp1.txt $expandedlexicon || die "unable to copy tmp1.txt to exapnded lexicon"
  tmp=`basename $UserOov`
  echo user dictionary $tmp merged by overruling into bg lexicon >> $STATUSFILE
done

cat $expandedlexicon | sort -u > $SCRATCHDIRECTORY/tmp.txt || die "unable to sort expanded lexicon"
cp $SCRATCHDIRECTORY/tmp.txt $expandedlexicon || die "unable to copy tmp.txt to exapnded lexicon"

echo expanded lex created by inserting  user *dict files, sorted >> $STATUSFILE

# KALDIbin=/vol/tensusers2/eyilmaz/local/bin # not necessary any more
OOVlexout=$INPUTDIRECTORY/LEX.out.oov

#./g2p.sh $INPUTDIRECTORY $expandedlexicon $OOVlexout $SCRATCHDIRECTORY $PLDIR $KALDIbin $G2PFSTfile
#echo -----g2p ---- 

./g2p.sh $INPUTDIRECTORY $expandedlexicon $OOVlexout $SCRATCHDIRECTORY $PLDIR $KALDIbin $G2PFSTfile 2> $SCRATCHDIRECTORY/g2p_problematic_words.txt || die "g2p failed"

#./g2p.sh $INPUTDIRECTORY $backgroundlexicon $OOVlexout $SCRATCHDIRECTORY $PLDIR $KALDIbin $G2PFSTfile
#detect oovs in all X.txt after normalisation
#apply p-saurus

cat $SCRATCHDIRECTORY/g2p_problematic_words.txt | perl -ne 'use open qw(:std :utf8); use utf8; chomp; @tok = split(/\s+/); printf("%s ??\n", $tok[$#tok]);' >> $INPUTDIRECTORY/g2p_problematic_words.txt

N=`cat $INPUTDIRECTORY/g2p_problematic_words.txt | wc -l`
echo $N problematic words for the g2p >> $STATUSFILE
echo ---start of listing--- >> $STATUSFILE
cat $INPUTDIRECTORY/g2p_problematic_words.txt >> $STATUSFILE
echo ---end of listing--- >> $STATUSFILE

echo g2p >> $STATUSFILE

foregroundlexicon=$INPUTDIRECTORY/foregroundlexicon.lex
cat $expandedlexicon $OOVlexout | sort -u > $foregroundlexicon || die "failure creating foregound lexicon"

nOOV=`cat $OOVlexout | wc -l`
echo $nOOV OOVs resolved by g2p, added >> $STATUSFILE
echo ---start of listing--- >> $STATUSFILE
cat $OOVlexout >> $STATUSFILE
echo ---end of listing--- >> $STATUSFILE

## here add the g2p problematic words with phone representation [SPN]

nproblems=`cat $INPUTDIRECTORY/g2p_problematic_words.txt | wc -l`
cat $INPUTDIRECTORY/g2p_problematic_words.txt | perl -ne 'chomp; @tok = split(/\s+/); $word = $tok[0]; $word = substr($word, 1, length($word)-2); printf("%s\t%s\n", $word, "[SPN]");' > $SCRATCHDIRECTORY/post_p2p_addons.lex

cat $foregroundlexicon $SCRATCHDIRECTORY/post_p2p_addons.lex | sort -u > $SCRATCHDIRECTORY/tmp_lex.txt
cp $SCRATCHDIRECTORY/tmp_lex.txt $foregroundlexicon || die "failure creating foreground lexicon"

echo added $nproblems remaining problematic words with pronunication SPN >> $STATUSFILE



### FA

pSPN=0.05
pSIL=0.05
./wav_tg2ali.sh $configfile $INPUTDIRECTORY $pSPN $pSIL $foregroundlexicon $RESOURCESDIRECTORY $KALDIbin2 $STATUSFILE || die "wav_tg2ali failed"
# X.wav + X.tg -> $INPUTDIRECTORY/log/final_ali.txt

echo wav_tg2ali >> $STATUSFILE

./detect_issues.sh $INPUTDIRECTORY >> $STATUSFILE || die "detect issues failed"

echo detect_issues >> $STATUSFILE

./finalali2ali.sh $INPUTDIRECTORY/log/final_ali.txt $INPUTDIRECTORY || die "finalali2ali failed"
# final_ali.txt -> X.ali

echo finalali2ali >> $STATUSFILE

./ali2ali_w.sh $INPUTDIRECTORY || die "ali2ali_w failed"
# X.ali + X.one2one_table -> X.aliphw2

echo ali2ali_w >> $STATUSFILE

# post processing transformations

#./ali_w2ctm.sh using ali2word_ctm.perl $audiofilename
#./ali_w2tg.sh using ali2tg_v2.perl

./ali_w2ctm.sh $INPUTDIRECTORY $PLDIR || die "ali_w2ctm failed"
# X.aliphw2 -> X.ctm # on wordlevel, requires name audiofile

echo ali_w2ctm >> $STATUSFILE

./ali_w2tg.sh $INPUTDIRECTORY $PLDIR || die "ali_w2tg failed"
#X.aliphw2 -> X_out.tg

echo ali_w2tg >> $STATUSFILE

#./ali_w2tar.sh $INPUTDIRECTORY $INPUTDIRECTORY/all.tar
# all X.ali_phw2 into all.tar

#echo ali_w2tar >> $STATUSFILE

./result2outputdir.sh $INPUTDIRECTORY $OUTPUTDIRECTORY || die "result2outputdir failed"


echo result2outputdir >> $STATUSFILE

./remove_wavs.sh $INPUTDIRECTORY || die "remove wavs failed"

echo remove_wavs >> $STATUSFILE


cd -

