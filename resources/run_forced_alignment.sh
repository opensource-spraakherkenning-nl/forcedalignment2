#!/bin/bash
#SBATCH --mem=2G
#SBATCH -N 1 -n 2

# pSIL and pSPN: see below

# Location of config file
config_file="align_config.rc"
usage="Usage: $0 [--config <path-to-config-file>] <subfolder-of-root-specified-in-config-file>"
main_folder_wav=""
# Create a tier in the resulting file containing the phone alignment. Default: 1
create_phone_alignment_tier=1


#if [ $# -eq 3 ]; then
#    if [ $1 == "--config" ] && [ ! $2 == "" ]; then
#   config_file=$2
#    else
#   echo "Error: argument/option '$1' not recognized!"
#   echo $usage
#   exit 1
#    fi
#    main_folder_wav=$3
#elif [ $# -eq 1 ]; then
#    main_folder_wav=$1
#elif [ $# -gt 3 ]; then
#    echo "Error: multiple arguments were specified, but only the option '--config' option is allowed!"
#    echo $usage
#    exit 1
#elif [ $# -eq 0 ]; then
#    echo "Error: one argument is required, see usage below."
#    echo $usage
#    exit 1
#fi

ignore=$1 # --config
config_file=$2
main_folder_wav=$3
pSPN=$4
pSIL=$5
backgroundlexicon=$6
KALDIbin2=$7 #ali-to-phones # test to kick this out, should be in PATH
STATUSFILE=$8

#was  ~/clst-asr-fa/lexicon.txt

[ -f path.sh ] && . ./path.sh
set -e

echo RUN FORCED ALIGNMENT SH >&2

#which extract_segments >> $STATUSFILE
#which compute_mfcc_feats >> $STATUSFILE
#which copy-feats >> $STATUSFILE

#which extract_segments 1>&2
#which compute_mfcc_feats 1>&2
#which copy-feats 1>&2

export train_cmd=run.pl
export decode_cmd=run.pl
export cuda_cmd=run.pl
export mkgraph_cmd=run.pl

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../../../tools/openfst/lib/

# Python compiler location (only tested with Python2.7.x), default: python
python_cmd=python3   # changed louis Oct 2020

# echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  AA
die() {
    echo "-------------- fatal error ----------------" >&2
    echo "$1" >&2
    echo "-------------------------------------------" >&2
    exit 2
}

# Load configurations
if [ ! -f "$config_file" ]; then
    die "config file not found ($config_file)"
fi
. "$config_file"

if [ "$root_data_folder" != "" ]; then
    main_folder_wav=$root_data_folder/$main_folder_wav
fi
if [ "$alignments_folder" == "" ]; then
    alignments_folder=$main_folder_wav
fi
if [ ! -d "$main_folder_wav" ]; then
    echo "'$main_folder_wav' is not a folder! Please check your script arguments."
    echo $usage
    exit 1
fi
if ! which sed; then
    die "sed not found"
fi
if ! which awk; then
    die "awk not found"
fi
if ! which $python_cmd; then
    die "python not found ($python_cmd)"
fi
aligndir=${main_folder_wav}/log
target_folder=$(pwd)"/align2praat"
splits="${aligndir}/splits/"

echo stage = $stage >&2

#if [ $stage -le 1 ]; then
#    if [ $do_conversion -ge 1 ]; then
#       echo "Starting stage 1/7 - Conversion of wav files from 44.1 Khz to 16 Khz..."
#       #converts all .wav files to 16 khz files
#       ${python_cmd} convertaudiofiles.py --es=$src_encoding --ts=$src_format --rs=$src_sample_rate --cs=$src_nr_channels --et=signed-integer --tt=wav --rt=16000 --ct=1 --bt=16 --append-to-file-name=$append_to_file_name $main_folder_wav *.wav
#
#       echo "Stage 1/7 - Finished wav file conversion..."
#    else
#   echo "Skipping conversion of wav files..."
# fi

# wavfile sample frequency conversion

echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX >&2
echo MAIN FOLDER WAV $main_folder_wav >&2

channel=1
for wavfile in $(ls $main_folder_wav/*wav); do
  wav16kHz=`echo "$wavfile" | sed 's/\.wav/-16khz.wav/'`
  sox "$wavfile" -r 16000 "$wav16kHz" remix $channel || die "unable to convert $wavfile"
done

echo $wav16khz 1>&2

echo "Stage 1/4 - Converting TextGrid files to UTF-8 encoding if necessary..." >&2
# Convert textgrids that are in UTF-16BE format to UTF-8 format for easier processing in
# scripts used further down
for file in $(find "${main_folder_wav}" -name '*.tg'); do
    src_encoding=`file -i "$file"`
    from_encoding=""
    if [[ $src_encoding == *"utf-16be"* ]]
    then
        from_encoding="utf-16be"
    elif [[ $src_encoding == *"utf-16le"* ]]
    then
        from_encoding="utf-16le"
    fi
    if [[ $from_encoding != "" ]]
    then
        iconv -f ${from_encoding} -t utf-8 "$file" -o "${file}-converted" || die "iconv not found"
        mv "${file}-converted" "$file"
        sed -i 's/^\xEF\xBB\xBF//' "$file" || die "unable to converted $file to utf-8"
        echo "Converted $file from ${from_encoding} encoding to utf-8..." >&2
    fi
done
echo "Stage 1/4 - Finished conversion..." >&2
#fi


# cat $inputdir/${file_id}.txt | perl utils/partition_text.perl "$datadir/"
#
#
#  breakpoints=(0)
#  for breakpoint in $(cat $datadir/breakpoints.txt)
#  do
#  echo ">>> " $breakpoint
#  breakpoints=(${breakpoints[@]} $breakpoint)
#  done
#  wavdur=`sox $inputfile -n stat 2>&1 | grep Length | awk '{print $3}'`
#  breakpoints=(${breakpoints[@]} $wavdur)
#
#  echo ${breakpoints[@]}
#
#  for j in $(seq 2 ${#breakpoints[@]})
#  do
#  jmin2=`echo $j | awk '{print ($1-2)}'`
#  jmin1=`echo $j | awk '{print ($1-1)}'`
#  onset=${breakpoints[$jmin2]}
#  offset=${breakpoints[$jmin1]}
#  dur=`echo $offset $onset | awk '{print $1-$2}'`
#  echo sox $inputfile $datadir/tmp"$jmin2".wav trim $onset $dur
#  sox $inputfile $datadir/tmp"$jmin2".wav trim $onset $dur
#  echo -------------------------


if [ $stage -le 2 ]; then
    echo "Starting stage 2/4 - Creating lexicon per utterance and force aligning them..." >&2
    echo "Creating filelist..." >&2
    mkdir -p "${aligndir}"
    for filename in $(find "${main_folder_wav}" -name "*-16khz.wav" -type f -print0 | xargs -0 echo);
    do
        filename_only=$(basename $filename)
        #if [[ ${filename_only} != *"extemporaneous"* ]]; then
        filename_len=${#filename_only}
                filename_only=${filename_only:0:${filename_len}-4}
        datadir=$aligndir/${filename_only}
        if [ ! -f "$aligndir/$filename_only/ali.1.ctm" ];
        then
            mkdir -p $datadir $datadir/dict
            # Copy base files for FST language model
            cp -p data/local/dict_osnl/extra_questions.txt data/local/dict_osnl/nonsilence_phones.txt data/local/dict_osnl/optional_silence.txt data/local/dict_osnl/phones.txt data/local/dict_osnl/silence_phones.txt $datadir/dict


            #Preparing wav.scp, segments, utt2spk, spk2utt text file and dictionary for $filename "..."
            echo ${python_cmd} data/local/data_prep.py --align_tier_name $align_tier_name --speaker_adapt SA --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --dict_file $backgroundlexicon >&2
            env LC_ALL=en_US.UTF-8 ${python_cmd} data/local/data_prep.py --align_tier_name $align_tier_name --speaker_adapt SA --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --dict_file $backgroundlexicon >&2 || die "data_prep failed"


            # what are the OOVs?

            #ls -d ${datadir}/dict/*
            #cat  ${datadir}/dict/lexicon.txt

            # file  ${datadir}/lang/words.txt does not exist yet
            echo PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP >&2


            #Calculating MFCC features from" + filename + "..."
            mkdir -p $datadir/mfcc
            mfccdir=$datadir/mfcc
            steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 $datadir $datadir/log $mfccdir >&2 || die "make_mfcc failed"
            utils/fix_data_dir.sh $datadir >&2 || die "fix_data_dir failed (1)"
            steps/compute_cmvn_stats.sh $datadir $datadir/log $mfccdir >&2 || die "compute_cmvn_stats failed"
            utils/fix_data_dir.sh $datadir >&2 || die "fix_data_dir failed (2)"

            #echo RUN MMMMMMMMMMMMMMMMMMMM
            #ls -d ${datadir}/dict/*

            # Preparing language resources directory" + filename + "..."
            echo utils/prepare_lang.sh --sil_prob 0.05 --position-dependent-phones true --num-sil-states 3 ${datadir}/dict UNK ${datadir}/tmp ${datadir}/lang >&2

            utils/prepare_lang.sh --sil_prob 0.05 --position-dependent-phones true --num-sil-states 3 ${datadir}/dict "<UNK>" ${datadir}/tmp ${datadir}/lang >&2 || die "prepare_lang failed"


            #cat ${datadir}/lang/words.txt
            #echo LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

            # Create simple linear FST LM for better alignment
            env LC_ALL=en_US.UTF-8 ${python_cmd} data/local/lang_prep_fst-lm.py --align_tier_name $align_tier_name --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --use_word_int_ids --dict_file $backgroundlexicon --pSPN $pSPN --pSIL $pSIL >&2 || die "lang_prep_fst-lm.py failed: --align_tier_name $align_tier_name --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --use_word_int_ids --dict_file $backgroundlexicon --pSPN $pSPN --pSIL $pSIL"

            # this creates a textfile G.fst.txt in $datadir/lang
            # of which the first line does not belong to the actual FST

            echo SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
            echo $datadir/lang
            ls $datadir/lang/G.fst.txt
            cat $datadir/lang/G.fst.txt
            ls $datadir/lang/L.fst
            #cat $datadir/lang/L.fst
            ls $datadir/lang/L00.txt
            cat $datadir/lang/L00.txt
            ls $datadir/lang/L_disambig.fst
            echo SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS

            # replace previous command by a cascade of smaller steps
            # 0: start from .wav filename ($filename)
            # 1: create .tg name from .wav filename, forget about "-16khz" tag
            intgname=`echo $filename | sed 's/\-16khz//' | sed 's/.wav/.tg/'`

            # 2: get path name of .wav file (use same for .tg)
            # 3: get orthography from .tg
            # assume the orthography resides on last line between double quotes
            echo orthography read from file $intgname >&2
            ortho=`cat $intgname | tail -1 | perl -ne 'm/\"(.*)\"/; printf("%s\n", $1);'`
            echo distilled ortho: $ortho
            #workingdir=$datadir
            #echo workingdir $workingdir
            #scriptdir=/home/ltenbosch/perl
            #scriptdir2="/home/ltenbosch/BNF2LATTICE/step1"
            #echo $ortho | perl $scriptdir/ortho2BNF.pl > $workingdir/BNF.txt
                        ## cp  $workingdir/BNF.txt ~ # for manipulation
                        #cp $workingdir/BNF.txt $workingdir/BNF.txt_BU

                        # ####### echo overwriting BNF.txt ... importing !!!!!!!!!!!!!!!!!
                        #cp ~/BNF.txt $workingdir/BNF.txt
                        #echo BNF.txt overwritten

                        # echo tim nam | perl $scriptdir/ortho2BNF.pl > $workingdir/BNF.txt

            # 4: build word-based FST from orthography
                        #echo workingdir/BNF.txt $workingdir/BNF.txt
                        #cat $workingdir/BNF.txt
                        #echo WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW

            #perl $scriptdir2/bnf_step1_v6.pl $workingdir/BNF.txt > $workingdir/FST_word.txt
                        #echo workingdir/FST_word.txt $workingdir/FST_word.txt
            #cat $workingdir/FST_word.txt
                        # 5: transform word-based FST to integer-based FST
            #ls ${datadir}/lang/words.txt
            #echo TTTTTTTTTTTTTTTTTTTTTT
            #head -20 ${datadir}/lang/words.txt

            #cat $workingdir/FST_word.txt | perl $scriptdir/FST_word2int.pl ${datadir}/lang/words.txt > $workingdir/FST_int.txt
            #echo output $workingdir/FST_int.txt
            #cat $workingdir/FST_int.txt

            # recreate $datadir/lang/G.fst.txt by overwriting
            #mv $datadir/lang/G.fst.txt  $datadir/lang/G.fst.txt_orig
            #cat $datadir/lang/G.fst.txt_orig | head -1 > $datadir/lang/G.fst.txt
            #cat $workingdir/FST_int.txt >> $datadir/lang/G.fst.txt
            # check:
                        #echo G.fst.txt
            #cat $datadir/lang/G.fst.txt
                        #echo UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
                        # in case of forced overwriting G
                        # echo forced overwriting G
                        #cp $datadir/lang/G.fst.txt $datadir/lang/G.fst.txt_BU
            # cp $datadir/lang/G.fst.txt ~/G.fst.txt_copy
                        #echo copy G.fst made
                        #cp ~/G.fst.txt_copy $datadir/lang/G.fst.txt
                        #echo overwritten
                        cat $datadir/lang/G.fst.txt
                        #echo VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
                        echo L_disambig.fst:
            echo $datadir/lang/L_disambig.fst
                        ls $datadir/lang/L_disambig.fst

            # Starting the actual process of aligning the transcriptions to audio..."
            # beam settings 5, 100
            steps/online/nnet2/align.sh --beam 5 --retry-beam 100 --cmd "$train_cmd" --nj 1 $datadir ${datadir}/lang $acmod $aligndir/$filename_only >&2 || die "ERROR: Could not decode ${filename}!\nERROR: Look at log in $aligndir/$filename_only/log/align.1.log."

            # added louis
            echo $src/bin/ali-to-phones --ctm-output $acmod/final.mdl gunzip $aligndir/$filename_only/ali.1.gz

            #$src/bin/ali-to-phones --ctm-output $acmod/final.mdl ark:"gunzip -c $aligndir/$filename_only/ali.1.gz|" -> $aligndir/$filename_only/ali.1.ctm;
            #$KALDIbin2/
            which ali-to-phones
            ali-to-phones --ctm-output $acmod/final.mdl ark:"gunzip -c $aligndir/$filename_only/ali.1.gz|" -> $aligndir/$filename_only/ali.1.ctm || die "ali-to-phones failed"


            # Remove copied acoustic model file 'final.mdl'
            rm -f $aligndir/$filename_only/final.mdl
        else
            echo "Skipping processing of file '$filename'. Result file '$aligndir/$filename_only/ali.1.ctm' already exists!" >&2
        fi
                #else
                #   echo "Skipping $filename, because it is an extemporaneous recording."
                #fi
    done

    echo "Finished stage 2/4" >&2
fi




if [ $stage -le 3 ]; then
    echo "Starting stage 3/4 - Merging all individual alignment files into one large file..." >&2
    # Stage 3 is to merge all the CTM formatted alignments into one big text file and to merge the segment files
    mergefile="${aligndir}/merged_alignment.txt"
    truncate -s 0 $mergefile || die "failed to truncate $mergefile" #empty the old mergefile
    find ${aligndir} -type f -name "*.ctm" | while read -r ctmfile; do
        cat ${ctmfile} >> $mergefile
    done;
    #cat $mergefile | wc -l

    segmentfile="${aligndir}/segments"
    truncate -s 0 $segmentfile || die "failed to truncate $segmentfile" #empty the old segmentfile
    find ${aligndir} -type d -name "*-16khz" -print | while read -r wavdir; do
        cat "${wavdir}/segments" >> $segmentfile
    done;
    #cat $segmentfile | wc -l

    echo "Finished stage 3/4" >&2
fi


if [ $stage -le 4 ]; then
    echo "Starting stage 4/4 - Converting phone integer IDs to textual equivalents and obtaining word alignment file..." >&2
    # Convert the phone numbers (integers) in the text file from stage 3 to the textual phones
    #filename_only=$(basename $filename)
    #${target_folder}/id2phone.R data/local/dict_osnl/phones.txt ${aligndir}/segments ${aligndir}/merged_alignment.txt ${aligndir}/final_ali.txt
    env LC_ALL=en_US.UTF-8 ${python_cmd} ${target_folder}/id2phone.py --phonefile data/local/dict_osnl/phones.txt --segmentfile ${aligndir}/segments --alignfile ${aligndir}/merged_alignment.txt --outputfile ${aligndir}/final_ali.txt || die "id2phone failed"

    echo ${aligndir}/final_ali.txt >&2
    cat ${aligndir}/final_ali.txt
    echo PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP


    # Not sure what this exactly does, but it seems to split the above modified text file for sorting
    # and applying the proper order of entries
    rm -rf ${splits}
    mkdir -p ${splits}
    sed '1d' ${aligndir}/final_ali.txt | awk -v var="${splits}" '{f= var $1 ".txt"; print > f}'
    for file in ${splits}*; do
        LC_ALL=C sort -n -k 10 -o ${file} ${file}
    done;
    # Adds the position of the phone in the word (beginning, centre, end or whole word)
    env LC_ALL=en_US.UTF-8 ${python_cmd} ${target_folder}/phons2pron.py ${splits} ${aligndir}/pron_alignment.txt >&2 || die "phons2pron failed"
    # Converts the above phone alignments to word alignments
    env LC_ALL=en_US.UTF-8 ${python_cmd} ${target_folder}/pron2words.py ${aligndir} ${aligndir}/pron_alignment.txt ${aligndir}/word_alignments.txt >&2 || die "pron2words failed"
    # Possibly, this is code to remove all the phone position markers, which is required for the next stage
    for file in ${splits}*; do
                LC_ALL=C sort -n -k 10 -o ${aligndir}/temp.txt ${file}
        echo "$header" | cat - ${aligndir}/temp.txt > "$file"
        file_base="$(basename $file)"
        IFS="_" read -ra fields <<< ${file_base}
        #for((i=0; i<=${#fields[@]}-2; i+=1)); do file_base+=${fields[$i]}"_"; done
        final_pos=$((${#file_base}-4))
        #file_base=${file_base:0:$final_pos}
        cat $file | sed 's/\_B//g' | sed 's/\_S//g' | sed 's/\_E//g' | sed 's/\_I//g' > ${splits}/${file_base:0:$final_pos}".tmp"
        #tail -n +2 ${splits}/${file_base:0:$final_pos}'.tmp'> ${splits}/${file_base:0:$final_pos}'.tmp'
        sed '1d' ${splits}/${file_base:0:$final_pos}'.tmp' | sponge ${splits}/${file_base:0:$final_pos}'.tmp'
        head -n 1 ${aligndir}/final_ali.txt > ${splits}/'firstrow.tmp'
        sed -i $'s/ /\t/g' ${splits}/'firstrow.tmp'
        cat ${splits}/'firstrow.tmp' ${splits}/${file_base:0:$final_pos}".tmp" > $file #add column names
    done;

    echo "Finished stage 4/4" >&2
fi



echo "Alignment process completed!">&2
