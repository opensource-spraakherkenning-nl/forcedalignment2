#!/bin/bash
#SBATCH --mem=2G
#SBATCH -N 1 -n 2

# Location of config file
config_file="align_config.rc"
usage="Usage: $0 [--config <path-to-config-file>] <subfolder-of-root-specified-in-config-file>"
main_folder_wav=""
# Create a tier in the resulting file containing the phone alignment. Default: 1
create_phone_alignment_tier=1

if [ $# -eq 3 ]; then
    if [ $1 == "--config" ] && [ ! $2 == "" ]; then
	config_file=$2
    else
	echo "Error: argument/option '$1' not recognized!"
	echo $usage
	exit 1
    fi
    main_folder_wav=$3
elif [ $# -eq 1 ]; then
    main_folder_wav=$1
elif [ $# -gt 3 ]; then
    echo "Error: multiple arguments were specified, but only the option '--config' option is allowed!"
    echo $usage
    exit 1
elif [ $# -eq 0 ]; then
    echo "Error: one argument is required, see usage below."
    echo $usage
    exit 1
fi

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh
set -e

export train_cmd=run.pl 
export decode_cmd=run.pl
export cuda_cmd=run.pl
export mkgraph_cmd=run.pl

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:../../../tools/openfst/lib/

# Praat location, default: praat
praat_cmd="praat --run"
# Python compiler location (only tested with Python2.7.x), default: python
python_cmd=python

# Load configurations
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
aligndir=${main_folder_wav}/log
target_folder=$(pwd)"/align2praat"
splits="${aligndir}/splits/"

echo stage = $stage

if [ $stage -le 1 ]; then
    if [ $do_conversion -ge 1 ]; then
	    echo "Starting stage 1/7 - Conversion of wav files from 44.1 Khz to 16 Khz..."
	    #converts all .wav files to 16 khz files
	    ${python_cmd} convertaudiofiles.py --es=$src_encoding --ts=$src_format --rs=$src_sample_rate --cs=$src_nr_channels --et=signed-integer --tt=wav --rt=16000 --ct=1 --bt=16 --append-to-file-name=$append_to_file_name $main_folder_wav *.wav

	    echo "Stage 1/7 - Finished wav file conversion..."
    else
	echo "Skipping conversion of wav files..."
    fi

	echo "Stage 1/7 - Converting TextGrid files to UTF-8 encoding if necessary..."
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
            iconv -f ${from_encoding} -t utf-8 "$file" -o "${file}-converted"
            mv "${file}-converted" "$file"
            sed -i 's/^\xEF\xBB\xBF//' "$file"
            echo "Converted $file from ${from_encoding} encoding to utf-8..."
	    fi
	done
    echo "Stage 1/7 - Finished conversion..."
fi

if [ $stage -le 2 ]; then
	echo "Starting stage 2/7 - Creating lexicon per utterance and force aligning them..."
	echo "Creating filelist..."
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
			echo ${python_cmd} data/local/data_prep.py --align_tier_name $align_tier_name --speaker_adapt SA --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --dict_file ~/clst-asr-fa/lexicon.txt
			${python_cmd} data/local/data_prep.py --align_tier_name $align_tier_name --speaker_adapt SA --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --dict_file ~/clst-asr-fa/lexicon.txt


#ls -d ${datadir}/dict/*
#cat  ${datadir}/dict/lexicon.txt

# file  ${datadir}/lang/words.txt does not exist yet
echo PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP

			
			#Calculating MFCC features from" + filename + "..."
			mkdir -p $datadir/mfcc
			mfccdir=$datadir/mfcc
			steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 $datadir $datadir/log $mfccdir
			utils/fix_data_dir.sh $datadir
			steps/compute_cmvn_stats.sh $datadir $datadir/log $mfccdir
			utils/fix_data_dir.sh $datadir

#echo RUN MMMMMMMMMMMMMMMMMMMM
#ls -d ${datadir}/dict/*

			# Preparing language resources directory" + filename + "..."
                        echo utils/prepare_lang.sh --sil_prob 0.05 --position-dependent-phones true --num-sil-states 3 ${datadir}/dict UNK ${datadir}/tmp ${datadir}/lang

			utils/prepare_lang.sh --sil_prob 0.05 --position-dependent-phones true --num-sil-states 3 ${datadir}/dict "<UNK>" ${datadir}/tmp ${datadir}/lang


#cat ${datadir}/lang/words.txt
#echo LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

			# Create simple linear FST LM for better alignment
			${python_cmd} data/local/lang_prep_fst-lm.py --align_tier_name $align_tier_name --wav_file $filename --annot_folder ${main_folder_wav} --data_folder $datadir --use_word_int_ids --dict_file ~/clst-asr-fa/lexicon.txt || continue

			# this creates a textfile G.fst.txt in $datadir/lang
			# of which the first line does not belong to the actual FST

			echo SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
			ls $datadir/lang/G.fst.txt
			cat $datadir/lang/G.fst.txt
			ls $datadir/lang/L.fst


			# replace previous command by a cascade of smaller steps
			# 0: start from .wav filename ($filename)
			# 1: create .tg name from .wav filename, forget about "-16khz" tag
			intgname=`echo $filename | sed 's/\-16khz//' | sed 's/.wav/.tg/'`

			# 2: get path name of .wav file (use same for .tg)
			# 3: get orthography from .tg
			# assume the orthography resides on last line between double quotes
                        echo orthography read from file $intgname
			ortho=`cat $intgname | tail -1 | perl -ne 'm/\"(.*)\"/; printf("%s\n", $1);'`
			echo distilled ortho: $ortho
			workingdir=$datadir
			echo workingdir $workingdir
			scriptdir=/home/ltenbosch/perl
			scriptdir2="/home/ltenbosch/BNF2LATTICE/step1"
			echo $ortho | perl $scriptdir/ortho2BNF.pl > $workingdir/BNF.txt
                        # cp  $workingdir/BNF.txt ~ # for manipulation
                        cp $workingdir/BNF.txt $workingdir/BNF.txt_BU

                        # ####### echo overwriting BNF.txt ... importing !!!!!!!!!!!!!!!!!
                        #cp ~/BNF.txt $workingdir/BNF.txt
                        #echo BNF.txt overwritten
			
                        # echo tim nam | perl $scriptdir/ortho2BNF.pl > $workingdir/BNF.txt

			# 4: build word-based FST from orthography
                        echo workingdir/BNF.txt $workingdir/BNF.txt
                        cat $workingdir/BNF.txt
                        echo WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW

			perl $scriptdir2/bnf_step1_v6.pl $workingdir/BNF.txt > $workingdir/FST_word.txt
                        echo workingdir/FST_word.txt $workingdir/FST_word.txt
			cat $workingdir/FST_word.txt
                        # 5: transform word-based FST to integer-based FST
			#ls ${datadir}/lang/words.txt
			echo TTTTTTTTTTTTTTTTTTTTTT
			head -20 ${datadir}/lang/words.txt
			
			cat $workingdir/FST_word.txt | perl $scriptdir/FST_word2int.pl ${datadir}/lang/words.txt > $workingdir/FST_int.txt
			echo output $workingdir/FST_int.txt
			cat $workingdir/FST_int.txt

			# recreate $datadir/lang/G.fst.txt by overwriting
			mv $datadir/lang/G.fst.txt  $datadir/lang/G.fst.txt_orig
			cat $datadir/lang/G.fst.txt_orig | head -1 > $datadir/lang/G.fst.txt 
			cat $workingdir/FST_int.txt >> $datadir/lang/G.fst.txt
			# check:
                        echo G.fst.txt
			cat $datadir/lang/G.fst.txt
                        echo UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
                        # in case of forced overwriting G
                        # echo forced overwriting G
                        #cp $datadir/lang/G.fst.txt $datadir/lang/G.fst.txt_BU
                        #echo copy made
                        #cp ~/G.fst.txt $datadir/lang/G.fst.txt 
                        #echo overwritten
                        #cat $datadir/lang/G.fst.txt
                        #echo VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

			echo $datadir/lang/L_disambig.fst
                        ls $datadir/lang/L_disambig.fst

			# Starting the actual process of aligning the transcriptions to audio..."
			# beam settings 5, 100
                        steps/online/nnet2/align.sh --beam 5 --retry-beam 100 --cmd "$train_cmd" --nj 1 $datadir ${datadir}/lang $acmod $aligndir/$filename_only || (echo -e "ERROR: Could not decode ${filename}!\nERROR: Look at log in $aligndir/$filename_only/log/align.1.log.");

			# added louis
			echo $src/bin/ali-to-phones --ctm-output $acmod/final.mdl gunzip $aligndir/$filename_only/ali.1.gz 

			$src/bin/ali-to-phones --ctm-output $acmod/final.mdl ark:"gunzip -c $aligndir/$filename_only/ali.1.gz|" -> $aligndir/$filename_only/ali.1.ctm;
			# Remove copied acoustic model file 'final.mdl'
			rm -f $aligndir/$filename_only/final.mdl
		else
			echo "Skipping processing of file '$filename'. Result file '$aligndir/$filename_only/ali.1.ctm' already exists!"
		fi
                #else
                #	echo "Skipping $filename, because it is an extemporaneous recording."
                #fi
	done

	echo "Finished stage 2/7"	
fi


if [ $stage -le 3 ]; then
	echo "Starting stage 3/7 - Merging all individual alignment files into one large file..."
	# Stage 3 is to merge all the CTM formatted alignments into one big text file and to merge the segment files
	mergefile="${aligndir}/merged_alignment.txt"
	truncate -s 0 $mergefile #empty the old mergefile
	find ${aligndir} -type f -name "*.ctm" | while read -r ctmfile; do
		cat ${ctmfile} >> $mergefile
	done;
	#cat $mergefile | wc -l
	
	segmentfile="${aligndir}/segments"
	truncate -s 0 $segmentfile #empty the old segmentfile
	find ${aligndir} -type d -name "*-16khz" -print | while read -r wavdir; do
		cat "${wavdir}/segments" >> $segmentfile
	done;
	#cat $segmentfile | wc -l

	echo "Finished stage 3/7"
fi


if [ $stage -le 4 ]; then
	echo "Starting stage 4/7 - Converting phone integer IDs to textual equivalents and obtaining word alignment file..."	
	# Convert the phone numbers (integers) in the text file from stage 3 to the textual phones
	#filename_only=$(basename $filename)
	#${target_folder}/id2phone.R data/local/dict_osnl/phones.txt ${aligndir}/segments ${aligndir}/merged_alignment.txt ${aligndir}/final_ali.txt
	${python_cmd} ${target_folder}/id2phone.py --phonefile data/local/dict_osnl/phones.txt --segmentfile ${aligndir}/segments --alignfile ${aligndir}/merged_alignment.txt --outputfile ${aligndir}/final_ali.txt
	# Not sure what this exactly does, but it seems to split the above modified text file for sorting
	# and applying the proper order of entries
	rm -rf ${splits}
	mkdir -p ${splits}
	sed '1d' ${aligndir}/final_ali.txt | awk -v var="${splits}" '{f= var $1 ".txt"; print > f}'
	for file in ${splits}*; do
		LC_ALL=C sort -n -k 10 -o ${file} ${file}
	done;
	# Adds the position of the phone in the word (beginning, centre, end or whole word)
	${python_cmd} ${target_folder}/phons2pron.py ${splits} ${aligndir}/pron_alignment.txt
	# Converts the above phone alignments to word alignments
	${python_cmd} ${target_folder}/pron2words.py ${aligndir} ${aligndir}/pron_alignment.txt ${aligndir}/word_alignments.txt
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

	echo "Finished stage 4/7"
fi

stage=10 # necessary since sometimes errors occur: "Cannot add a boundary at ... seconds, because this is outside the time domain of the intervals"

if [ $stage -le 5 ]; then
	if [ $create_phone_alignment_tier -ge 1 ]; then
	    echo "Starting stage 5/7 - Creating Praat TextGrid files containing phone alignment..."
	    ${praat_cmd} ${target_folder}/createtextgrid.praat "${splits}" "${main_folder_wav}" "${phone_tier_name}"

	    echo "Finished stage 5/7"
	else
	    echo "Skipping stage 5/5 - Not creating phone alignment tier in final TextGrid file..."
	fi
fi


if [ $stage -le 6 ]; then
	echo "Starting stage 6/7 - Creating Praat TextGrid files containing word alignment..."
	${praat_cmd} ${target_folder}/createWordTextGrids.praat "${aligndir}" "${main_folder_wav}" "${splits}" "${word_tier_name}"

	echo "Finished stage 6/7"
fi


if [ $stage -le 7 ]; then
	echo "Starting stage 7/7 - Merging previously created textgrid files into one including tiers from transcription files..."
	# Copy textgrid files containing the manual transcriptions to also be able to
	# stack those.
	for file in $(find "${main_folder_wav}" -name "*-16khz.wav" -print0 | xargs -0 echo); do
	#for file in "${main_folder_wav}"/*.wav; do
	    file_base=$(basename $file)
	    final_pos=$((${#file_base}-10))
	    textgrid=${main_folder_wav}/${file_base:0:$final_pos}"_checked.tg"
	    if [ ! -f ${textgrid} ]
	    then
		textgrid=${main_folder_wav}/${file_base:0:$final_pos}".tg"
	    fi
	    cp -p ${textgrid} ${splits}/${file_base:0:$final_pos}-16khz_man.tg
	done;

	${praat_cmd} ${target_folder}/stackTextGrids.praat "${splits}" "${alignments_folder}"

	#rm -f ${splits}/*-16khz_man.tg

	# Convert textgrids that are in UTF-16BE format to UTF-8 format for easier processing in
	# additional scripts
	for file in $(find "${alignments_folder}" -name '*_aligned.tg'); do
	    src_encoding=`file -i "$file"`
	    if [[ $src_encoding == *"utf-16be"* ]]
	    then
		iconv -f utf-16be -t utf-8 "$file" -o "${file}-converted"
		mv "${file}-converted" "$file"
		sed -i 's/^\xEF\xBB\xBF//' "$file"
		echo "Converted $file from utf-16be encoding to utf-8..."
	    fi
	done

	# Correct tier end timings and names after the merge
	${python_cmd} ${target_folder}/correct-tier-timings-n-names.py "${alignments_folder}"

	echo "Finished stage 7/7"
fi
echo "Alignment process completed!"
