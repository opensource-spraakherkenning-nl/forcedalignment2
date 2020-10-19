#! /usr/bin/python
# coding=utf-8
import os, sys, getopt, logging
import subprocess, time
from fnmatch import fnmatch
logging.basicConfig(level=logging.DEBUG)

# Example usage: python convertaudiofiles.py --es=signed-integer --ts=wav --rs=44100 --cs=1 --et=signed-integer --tt=wav --rt=16000 --ct=1 --append-to-file-name=-16khz <directory with wav files> *.wav

def help():
    print  (get_script_name() + " - Script that converts all audio files in a specified directory specified " + \
            "by a pattern from a source encoding to a target encoding. Including the matched audio files in all " + \
            "subdirectories.\nFor this conversion the Sound eXchange (SoX) command line utility is used and " + \
            "should be on the PATH environment variable. See http://sox.sourceforge.net.\n\n")
    usage()
    print ("\nOptions:\n" + \
            "-h    --help                    Show this help message.\n" + \
            "--es=<value>                    Encoding of source file (e.g. a-law, (un)signed-integer, ms-adpcm, etc. " + \
                                            "see -e option in 'sox --help').\n" + \
            "--ts=<value>                    Type of source file (e.g. wav, raw, etc. see -t option in 'sox --help').\n" + \
            "--rs=<value>                    Sample rate of source file (e.g. 8000, 16000, etc. see -r option in 'sox " + \
                                            "--help').\n" + \
            "--cs=<value>                    Number of channels in source file (e.g. 1 = mono, 2 = stereo, etc.).\n\n" + \
            "--et=<value>                    Encoding of target file (e.g. a-law, (un)signed-integer, ms-adpcm, etc. " + \
                                            "see -e option in 'sox --help').\n" + \
            "--tt=<value>                    Type of target file (e.g. wav, raw, etc. see -t option in 'sox --help').\n" + \
            "--rt=<value>                    Sample rate of target file (e.g. 8000, 16000, etc. see -r option in 'sox " + \
                                            "--help').\n" + \
            "--ct=<value>                    Number of channels in target file (e.g. 1 = mono, 2 = stereo, etc.).\n" + \
            "--append-to-file-name=<value>   String that is appended to the file name of the converted files. Default: -copy")

def usage():
    print   ("Usage: " + get_script_name() + " <options> <full path to directory with audio files> <reg. exp. string " + \
             "to match audio file names>")

""" Main function that is run when this script is invoked from the command line."""
def main(argv):
    if len(argv) >= 2 and len(argv) <= 12:
        try:
            opts, args = getopt.getopt(argv, "h", ["append-to-file-name=", "ts=", "tt=", "es=",
                                                   "cs=", "et=", "rs=", "rt=", "ct=", "bt=", "help"])
        # Python2.7 except getopt.GetoptError, goe:
        except getopt.GetoptError as goe:
            print "Error: " + str(goe)
            usage()
            sys.exit(2)

        if len(args) == 2:
            arg_values = dict()

            for opt, arg in opts:
                if opt in ("-h", "--help"):
                    help()
                    sys.exit()
                else:
                    arg_values[opt] = arg

            if args[0].endswith("/"):
                args[0] = args[0][:-1]
            # Check if directory exists and is not a file
            if os.path.isdir(args[0]):
                logging.info(time.asctime(time.localtime()) + " - Reading '" + args[0] + "'.")
                successful = 0;
                for path, subdirs, files in os.walk(args[0]):
                    for name in files:
                        if fnmatch(name, args[1]):
                            fname = os.path.join(path, name)
                            # Check for extension, and if there is one replace it with the new type
                            index = fname.rfind(".")
                            tname = fname + "."
                            if index == len(fname) - 4:
                                tname = fname[0:index]
                            cmd = ["sox"]
                            cmd.append('-e'), cmd.append(arg_values.get("--es")) if arg_values.get("--es") != None else ""
                            cmd.append('-r'), cmd.append(arg_values.get("--rs")) if arg_values.get("--rs") != None else ""
                            cmd.append('-t'), cmd.append(arg_values.get("--ts")) if arg_values.get("--ts") != None else ""
                            cmd.append('-c'), cmd.append(arg_values.get("--cs")) if arg_values.get("--cs") != None else ""
                            cmd.append(fname)
                            cmd.append('-e'), cmd.append(arg_values.get("--et")) if arg_values.get("--et") != None else ""
                            cmd.append('-t'), cmd.append(arg_values.get("--tt")) if arg_values.get("--tt") != None else ""
                            cmd.append('-r'), cmd.append(arg_values.get("--rt")) if arg_values.get("--rt") != None else ""
                            cmd.append('-c'), cmd.append(arg_values.get("--ct")) if arg_values.get("--ct") != None else ""
                            cmd.append('-b'), cmd.append(arg_values.get("--bt")) if arg_values.get("--bt") != None else ""
                            if arg_values.get("--append-to-file-name") != None:
                                # if the conversion is already done skip

                                tname += arg_values.get("--append-to-file-name")
                            if arg_values.get("--tt") != None:
                                cmd.append(tname + "." + arg_values.get("--tt"))
                            elif arg_values.get("--append-to-file-name") == None:
                                tname += "-copy"
                                if index > -1:
                                    tname += fname[index:]
                                cmd.append(tname)
                            logging.info(time.asctime(time.localtime()) + " - Calling SoX binary with '" + " ".join(cmd) + "'...")
                            logging.info(time.asctime(time.localtime()) + " - Output of SoX follows:")

                            return_value = subprocess.call(cmd)
                            if return_value == 0:
                                logging.info(time.asctime(time.localtime()) + " - SoX returned with code 0, conversion successful!")
                                successful += 1
                            else:
                                return return_value
                logging.info(time.asctime(time.localtime()) + " - " + str(successful) + " files successfully converted in total.")
            else:
                logging.error(time.asctime(time.localtime()) + " - Error: provided directory '" + args[0] + "' does not seem to exist. Please " + \
                        "check the syntax of the first argument.")
        else:
            logging.error(time.asctime(time.localtime()) + " - Only max. 11 arguments allowed!")
            usage();
    else:
        if "--help" in argv:
            help()
        elif len(argv) > 11:
            logging.error(time.asctime(time.localtime()) + " - Too many arguments. Max. 11 allowed.")
            usage();
        elif len(argv) < 2:
            logging.error(time.asctime(time.localtime()) + " - Arguments missing. At least 2 required.")
            usage();

    logging.shutdown()

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
    main(sys.argv[1:])
