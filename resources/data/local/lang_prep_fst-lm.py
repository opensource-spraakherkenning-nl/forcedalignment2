import argparse
import os
import sys
import math
from praat import textgrid

def main(argv):
    parser = argparse.ArgumentParser(description='Lexicon preparation')
    parser.add_argument('--wav_file', help='the wav file that is being preprocessed', type=str, required=True)
    parser.add_argument('--annot_folder', help='the folder with the tg files that is used for preprocessing', type=str, required=True)
    parser.add_argument('--data_folder', help='the data folder with the dictionaries, text, segments, utt2spk and wav.scp files', type=str,required=True)
    parser.add_argument('--align_tier_name', help='Prepare the text from the tier with this name in every textgrid file. Default: transcription', type=str, default="transcription")
    parser.add_argument('--use_word_int_ids', help='Add this option to generate a FST LM with word integer IDs (e.g. from a Kaldi word.txt file) instead of the actual word strings. Default: False', action='store_true')
    parser.add_argument('--dict_file', help='Main lexicon that contains phoneme translations of regular words. Default: data/local/dict_osnl/lexicon.txt', \
        type=str, default=os.path.join(os.getcwd(),"data","local","dict_osnl","lexicon.txt"))
    parser.add_argument('--spkr_noise_sym', help='The word in the lexicon denoting speaker noise (e.g. lip smacks, tongue clicks, heavy breathing, etc). Default: <SPN>', \
        type=str, default="<SPN>")
    parser.add_argument('--gen_noise_sym', help='The word in the lexicon denoting general noise (e.g. environmental, microphone clicks, etc.). Default: <NSN>', \
        type=str, default="<NSN>")
    parser.add_argument('--pSPN', help='pSPN. Default 0.05', type=float, default=0.05)
    parser.add_argument('--pSIL', help='pSIL. Default 0.05', type=float, default=0.05)



    args = parser.parse_args()
    wav_file = args.wav_file
    main_folder_wav, filename = os.path.split(wav_file)
    main_folder_annot = args.annot_folder
    data_folder = args.data_folder
    pSPN = args.pSPN
    pSIL = args.pSIL

    dict_full = open(args.dict_file, "r", encoding="utf-8")

    # Check if a checked version of the transcribed recording is available. If
    # not, use the unchecked version.
    file_path = os.path.join(main_folder_annot,filename[:-len('-16khz.wav')]+'_checked.tg')
    if not(os.path.isfile(file_path)):
        file_path = os.path.join(main_folder_annot,filename[:-len('-16khz.wav')]+'.tg')
    print("Processing file '" + filename + "'...",file=sys.stderr)

    textgrid_fp = textgrid.Textgrid()
    textgrid_fp.read(file_path)
    trans_tier = textgrid_fp.get_tier_by_name(args.align_tier_name)
    if trans_tier != None:
        for interval in trans_tier.intervals:
            if interval.text != "" and '<empty>' not in interval.text and '<leeg>' not in interval.text:
                text=interval.text.replace(u'++', u''). \
                    replace(u'.', u'').replace(u',', u'').replace(u'?', u'').replace(u'*r', u'')
                #print(text)
                text = "".join(c for c in text if c not in  (u'!',u'.',u':',u'?',u',',u'\n',u'\r',u'"',u'|',u';',u'(',u')',u'[',u']',u'{',u'}',u'#',u'_',u'+',u'&lt',u'&gt',u'\\'))
                fields = text.lower().split()
                # louis: next lines changed since they prohibited words containing mm e.g. gezwommen to pass though
                for ele in fields:
                    if u'xxxxxxx' in ele or u'mmmmmmmm' in ele or u'gggggggggg' in ele:
                        ind=fields.index(ele)
                        fields[ind]=args.spkr_noise_sym
                    elif u'<opn>' in ele or u'<spk>' in ele:
                        ind=fields.index(ele)
                        fields[ind]=args.spkr_noise_sym
                text = u' '.join(fields)
                temp=text.strip().lower().split()
                text = u' '.join(temp)

                text = text.replace(args.spkr_noise_sym.lower(), args.spkr_noise_sym).replace(args.gen_noise_sym.lower(), args.gen_noise_sym).replace("<sil>", "<SIL>")

                # Create a strict, linear FST LM for every utterance
                fst_lm_fp = open(os.path.join(data_folder, "lang", "G.fst.txt"), mode="w", encoding="utf-8")
                fst_lines = [str(filename[:-len('.wav')]) + "\n"]
                if args.use_word_int_ids:
                    words_dict = {}
                    words_dict_fp = open(os.path.join(args.data_folder, "lang", "words.txt"), mode="r", encoding="utf-8")
                    for line in words_dict_fp:
                        line_split = line.split()
                        words_dict[line_split[0]] = line_split[1]
                    #pSPN = 0.001 # this does not always show the desired result
                    # maybe better to couple this prob to SIL as well
                    #pSPN = 0.005 # now in arg list
                    # pSIL = pSPN # now in arg list

                    int_lines = create_int_fst_for_utt(text.split(), words_dict,pSPN, pSIL)
                    if int_lines != None:
                        fst_lines += int_lines
                    else:
                        sys.stderr.write("Error in processing file '" + file_path + "'! The words.txt file is missing a word!" + \
                        " Check the dict/missing_words.txt log!\nAborting...\n")
                        sys.exit(1)
                else:
                    fst_lines += create_textual_fst_for_utt(text.split())
                fst_lm_fp.writelines(fst_lines)
                fst_lm_fp.close()

    else:
        sys.stderr.write("Error in processing file '" + file_path + "'! Could not find tier '" + args.align_tier_name + "' to process!\nAborting...\n")
        sys.exit(1)

"""
Creates a FST in text format for the specified utterance.
@param utt - String containing the utterance for which to create a FST in text
(minus annotation tags, interpunction characters, etc.). Words in the utterance
should be separated by a single whitespace character.
@return fst_lines - String array containing the lines that make up the FST.
"""
def create_textual_fst_for_utt(utt):
    sil = "<SIL>"
    spn = "<SPN>"

    fst_lines = []
    state_nr = 0
    word_nr = 0
    for word in utt:
        if word_nr < len(utt):
            fst_lines.append(str(state_nr) + " " + str(state_nr+1) + " " + word + " " + word + " " + str(-math.log(float(1.0/3))) + "\n")
            fst_lines.append(str(state_nr) + " " + str(state_nr+1) + " " + spn + " " + spn + " " + str(-math.log(float(1.0/3))) + "\n")
            fst_lines.append(str(state_nr) + " " + str(state_nr+1) + " " + sil + " " + sil + " " + str(-math.log(float(1.0/3))) + "\n")
            #fst_lines.append(str(state_nr) + " " + str(state_nr) + " " + sil + " " + sil + " " + str(-math.log(float(1.0/4))) + "\n")
        state_nr += 1

    # Add the final state at the end
    fst_lines.append(str(state_nr) + " 0.0")

    return fst_lines

"""
Creates a FST in text format for the specified utterance, but using the integer
IDs for the words instead of the word strings themselves.
@param utt - String containing the utterance for which to create a FST in text
(minus annotation tags, interpunction characters, etc.). Words in the utterance
should be separated by a single whitespace character.
@param words_dict - Dictionary containing a mapping between word strings and
their integer IDs.
@return fst_lines - String array containing the lines that make up the FST.
"""
def create_int_fst_for_utt(utt, words_dict, pSPN, pSIL):
    # print(utt)
    sil = words_dict["<SIL>"]
    spn = words_dict["<SPN>"]

    fst_lines = []
    state_nr = 0
    word_nr = 0
    for word in utt:
        if word_nr < len(utt):
            if word in words_dict:
                # print("qqqqqqqqqqqqqqq")
                # print(word)
                word = words_dict[word]
                # print(str(word))
                fst_lines.append(str(state_nr) + " " + str(state_nr+1) + " " + str(word) + " " + str(word) + " " + str(-math.log(float(0.9))) + "\n")
                fst_lines.append(str(state_nr) + " " + str(state_nr+1) + " " + str(spn) + " " + str(spn) + " " + str(-math.log(float(pSPN))) + "\n")
                fst_lines.append(str(state_nr) + " " + str(state_nr+1) + " " + str(sil) + " " + str(sil) + " " + str(-math.log(float(pSIL))) + "\n")
                state_nr += 1
            else:
                print(word)
                # A word from the transcription is missing stop generating the fst
                fst_lines = None
                break

    if fst_lines != None:
        # Add the final state at the end
        fst_lines.append(str(state_nr) + " 0.0")

    return fst_lines

if __name__ == '__main__':
    main(sys.argv[1:])
