#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys, os, glob, codecs, logging, getopt
from fnmatch import fnmatch
from praat import textgrid
from praat import intervaltier
from praat import interval
logging.basicConfig(format="%(levelname)-10s %(asctime)s %(message)s", level=logging.INFO)

# This script converts a directory of CTM files made with a Kaldi based
# recognition system to Praat TextGrid files in long syntax. It is also possible 
# to merge in the manual transcription tier and there's option to also add the
# confidence score from the CTM file on a separate tier.
# The following 2 arguments are required by the script: directory pointing to the 
# location of the manual transcriptions, full path to subdirectory 
# containing the Kaldi CTM files.
# Author: Mario Ganzeboom
# Last modification: September 19, 2017

def main(argv):
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h", ["help","add-cm","sym-ext="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    do_add_cm = False
    sym_ext = ".sym.ctm"
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()                 
            sys.exit()
        elif opt == "--add-cm":
            do_add_cm = True
        elif opt == "--sym-ext":
            sym_ext = arg

    print(args)
    if len(args) >= 1 and len(args) <= 2:
        transcription_root = None
        if len(args) >= 2:
            transcription_root = args[1]
        results_subdir = args[0]
        for ctm_file in os.listdir(results_subdir):
            if ctm_file.endswith(sym_ext):
                logging.info("Processing file '" + ctm_file + "'...")
                #sym_ext = ".sym.ctm"
                #if ctm_file.endswith(".ctm.sym"):
                #    sym_ext = ".ctm.sym"
                file_name_base = ctm_file[:-len(sym_ext)]+"_checked"
                if transcription_root == None or not(os.path.isfile(os.path.join(transcription_root, file_name_base+".tg"))):
                    file_name_base = ctm_file[:-len(sym_ext)]
                transcription_tg = None
                if transcription_root != None:
                    transcription_tg = textgrid.Textgrid()
                    transcription_tg.read(os.path.join(transcription_root, file_name_base+".tg"))
                    transcription_tier = transcription_tg.get_tier_by_name("transcription")
                    if transcription_tier == None:
                        transcription_tier = transcription_tg.get_tier_by_name("words")
                    transcription_tier.etime = transcription_tg.etime
                    transcription_tier.intervals[len(transcription_tier.intervals)-1].etime = transcription_tg.etime
                textgrid_file = textgrid.Textgrid()
                if transcription_root != None:
                    textgrid_file.etime = transcription_tg.etime
                    textgrid_file.tiers.append(transcription_tier)
                word_tier_intervals = create_tier_intervals_from_ctm(os.path.join(results_subdir, ctm_file), 4)
                word_tier = intervaltier.IntervalTier("kaldiwords", 0.0, word_tier_intervals[-1].etime, len(word_tier_intervals), word_tier_intervals)
                textgrid_file.tiers.append(word_tier)
                if do_add_cm:
                    cm_tier_intervals = create_tier_intervals_from_ctm(os.path.join(results_subdir, ctm_file), 5)
                    cm_tier = intervaltier.IntervalTier("kaldicm", 0.0, word_tier_intervals[-1].etime, len(cm_tier_intervals), cm_tier_intervals)
                    textgrid_file.tiers.append(cm_tier)
                if transcription_root == None:
                    word_tier_intervals[len(word_tier_intervals)-1].etime
                    textgrid_file.etime = word_tier.etime
                    textgrid_file.nr_tiers = 1
                    if do_add_cm:
                        cm_tier_intervals[len(cm_tier_intervals)-1].etime
                        textgrid_file.nr_tiers = 2
                else:
                    textgrid_file.nr_tiers += 2
                output_tg_file = os.path.join(results_subdir, file_name_base+"_linear-fst.tg")
                textgrid_file.write(output_tg_file)
                logging.info("Converted CTM for utterance '" + ctm_file + "' to TextGrid file '" + output_tg_file + "'...")
        if transcription_root == None:
            logging.warning("No manual transcription directory specified. End time of generated TextGrids might not coincide with the duration of the corresponding audio recording!")
    else:
        logging.error("This script requires 1 argument and the second is optional, please ensure that all are provided correctly!")
        usage()

def create_tier_intervals_from_ctm(path_to_ctm_file, content_idx):
    ctm_file = open(path_to_ctm_file, "r")
    intervals = []
    for line in ctm_file:
        line_comps = line.split()
        btime = float(line_comps[2])
        new_interval = interval.Interval(btime, btime+float(line_comps[3]), str(line_comps[content_idx]))
        intervals.append(new_interval)
        utt_id = line_comps[0]

    return intervals

def help():
    logging.info(get_script_name() + " - Merge a directory of Kaldi alignments optionally with corresponding manual transcriptions " + \
		"to a single Praat TextGrid file (in long notation format).\n")
    usage()
    logging.info("\nParameters:\n" + \
            "-h    --help        Show this help message")

def usage():
    logging.info("Usage: " + get_script_name() + " <dir. with CTM files ending on .sym.ctm> [<root dir. where the man. transcriptions and SPRAAK results are located>]")		
		
""" Error handler printing custom_msg through logging.error() and exception.message through logging.exception().
At the end sys.exit(2) is called to abort the script.

@param exception: The exception object containing specific codes and/or messages.
@param custom_msg: Message provided by the script/application explaining the exception.
"""
def handle_exception(exception, custom_msg):
    logging.error("An error occurred during execution, see messages below:")
    logging.error(custom_msg)
    if hasattr(exception, 'message'):
        logging.exception("" + exception.message)
    logging.shutdown()
    sys.exit(2);

""" Utility function to get the 'pretty printed' name of this script from the sys.argv[0] array.

@return: String containing the file name of this script (e.g. name-of-script.py, examplescript.py, etc.)
"""
def get_script_name():
    script_name = sys.argv[0]
    last_path_sep = script_name.rfind(os.sep)
    if last_path_sep > -1:
        script_name = script_name[last_path_sep+1:]
    
    return script_name

if __name__ == '__main__':
    main(sys.argv)
