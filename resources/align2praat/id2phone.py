import sys
import argparse
import pandas as pd

parser = argparse.ArgumentParser(description='Lexicon preparation')
parser.add_argument('--phonefile', help='insert textfile with all phones', type=str, required=True)
parser.add_argument('--segmentfile', help='file with all segments', type=str, required=True)
parser.add_argument('--alignfile', help='file with the alignment information', type=str, required=True)
parser.add_argument('--outputfile', help='location of the output', type=str, required=True)

args = parser.parse_args()
phonefile = args.phonefile
segmentfile = args.segmentfile
alignfile = args.alignfile
outputfile = args.outputfile


phones = pd.read_table(args.phonefile, delimiter=' ', names=["phone", "id"])
segments = pd.read_table(args.segmentfile, delimiter=' ', names=["file_utt","file","start_utt","end_utt"])
ctm = pd.read_table(args.alignfile, delimiter=' ', names=["file_utt","utt","start","dur","id"])
ctm["file"] = ctm["file_utt"]

#print(ctm)
ctm2 = pd.merge(ctm,phones,how='left',on='id')
ctm2.drop_duplicates()
#print(ctm2)
ctm3 = pd.merge(ctm2,segments,how='left',on=('file_utt', "file"))
#print(ctm3)
#sys.exit(1)

ctm3["start_real"] = ctm3["start"] + ctm3["start_utt"]
ctm3["end_real"] = ctm3["start_utt"] + ctm3["dur"]

ctm3 = ctm3[['file_utt','file','id','utt','start','dur','phone','start_utt','end_utt','start_real','end_real']]
ctm3.to_csv(args.outputfile,sep="\t",index=False)
