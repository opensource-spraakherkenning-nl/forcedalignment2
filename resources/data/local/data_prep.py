import argparse, codecs, os, sys
import numpy as np
import difflib
from praat import textgrid

reload(sys)
sys.setdefaultencoding('utf8')

parser = argparse.ArgumentParser(description='Lexicon preparation')
parser.add_argument('--speaker_adapt', help='indicates speaker dependent or independent recognition. values: SA or SI resp.', type=str, required=True)
parser.add_argument('--wav_file', help='the wav file that is being preprocessed', type=str, required=True)
parser.add_argument('--annot_folder', help='the folder with the tg files that is used for preprocessing', type=str, required=True)
parser.add_argument('--data_folder', help='the data folder with the dictionaries, text, segments, utt2spk and wav.scp files', type=str,required=True)
parser.add_argument('--align_tier_name', help='Prepare the text from the tier with this name in every textgrid file. Default: transcription', type=str, default="transcription")
parser.add_argument('--dict_file', help='Main lexicon that contains phoneme translations of regular words. Default: data/local/dict_osnl/lexicon.txt', \
    type=str, default=os.path.join(os.getcwd(),"data","local","dict_osnl","lexicon.txt"))
parser.add_argument('--spkr_noise_sym', help='The word in the lexicon denoting speaker noise (e.g. lip smacks, tongue clicks, heavy breathing, etc). Default: <SPN>', \
    type=str, default=u"<SPN>")
parser.add_argument('--gen_noise_sym', help='The word in the lexicon denoting general noise (e.g. environmental, microphone clicks, etc.). Default: <NSN>', \
    type=str, default=u"<NSN>")


args = parser.parse_args()
speaker_info = args.speaker_adapt
wav_file = args.wav_file
main_folder_wav, filename = os.path.split(wav_file)
main_folder_annot = args.annot_folder
data_folder = args.data_folder
spkr_noise_sym = args.spkr_noise_sym.decode("utf-8")

# Variables for storing the content that is later written to the corresponding files
new_txt = ''
new_seg = ''
new_utt = ''
new_wav = ''

fid_txt = codecs.open(os.path.join(data_folder,'text'),"w","utf-8")
fid_seg = codecs.open(os.path.join(data_folder,'segments'),"w","utf-8")
fid_utt = codecs.open(os.path.join(data_folder,'utt2spk'),"w","utf-8")
fid_wav = codecs.open(os.path.join(data_folder,'wav.scp'),"w","utf-8")

print args.dict_file
dict_full = codecs.open(args.dict_file, "rb", "utf-8")

dict = codecs.open(os.path.join(data_folder,'dict','lexicon.txt'), "w","utf-8")
dictp = codecs.open(os.path.join(data_folder,'dict','lexiconp.txt'), "w","utf-8")
missing = codecs.open(os.path.join(data_folder,'dict','missing_words.txt'), "w","utf-8")

# This loop goes over the above list of files and opens the corresponding manual
# transcriptions in PRAAT textgrid format which is either the short or long text
# format
#if '_Eg' in filename or '_Ag' in filename or '_Og' in filename:
#    continue
cnt3=0
cnt2=0
flag=0
flag2=0
utt_id = filename[:-4]
fields = filename.split('_')
speaker = fields[0]
cnt=4
inhibit=0
inhibit2=1
target_flag=0
tg_type='short'
text_buffer = []
s_time_buffer = []
e_time_buffer = []
# Check if a checked version of the transcribed recording is available. If
# not, use the unchecked version.
file_path = os.path.join(main_folder_annot,filename[:-len('-16khz.wav')]+'_checked.tg')
if not(os.path.isfile(file_path)):
    file_path = os.path.join(main_folder_annot,filename[:-len('-16khz.wav')]+'.tg')
print "Processing file '" + filename + "'..."


print "33333333333333333333333333333333333333333333333333333"

textgrid_fp = textgrid.Textgrid()
textgrid_fp.read(file_path)
trans_tier = textgrid_fp.get_tier_by_name(args.align_tier_name)
if trans_tier != None:
    for interval in trans_tier.intervals:
        if interval.text != "" and '<empty>' not in interval.text and '<leeg>' not in interval.text:
            text=interval.text.replace(u'++', u''). \
                replace(u'.', u'').replace(u',', u'').replace(u'?', u'').replace(u'*r', u'')
            #louis
            print "4444444444444444444444444444444444444444444444444444444444444"
            # print(text) # seems to give problems with non-range(128) characters
            text = u"".join(c for c in text if c not in  (u'!',u'.',u':',u'?',u',',u'\n',u'\r',u'"',u'|',u';',u'(',u')',u'[',u']',u'{',u'}',u'#',u'_',u'+',u'&lt',u'&gt',u'\\'))
            fields = text.lower().split()
            for ele in fields:
            # louis mm->mmm # changed to mmmmmm gggggg xxxxxx
                if u'*' in ele or u'xxxxxx' in ele or u'mmmmmm' in ele or u'gggggg' in ele:
                    ind=fields.index(ele)
                    fields[ind]=args.spkr_noise_sym
                elif u'<opn>' in ele or u'<spk>' in ele:
                    ind=fields.index(ele)
                    fields[ind]=args.spkr_noise_sym
            text = u' '.join(fields)
            temp=text.strip().lower().split()
            text = u' '.join(temp)
            text = text.replace(args.spkr_noise_sym.lower(), args.spkr_noise_sym).replace(args.gen_noise_sym.lower(), args.gen_noise_sym).replace("<sil>", "<SIL>")
            text_buffer.append(text)
            s_time_buffer.append(unicode("{:.3f}".format(interval.btime)))
            e_time_buffer.append(unicode("{:.3f}".format(interval.etime)))
else:
    sys.stderr.write("Error in processing file '" + file_path + "'! Could not find tier '" + args.align_tier_name + "' to process!\nAborting...\n")
    sys.exit(1)


# louis
print "yyyyyyyyyyyyy0000000000000000000 text: " + text.encode("utf8")

"""
print do we see this bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
for line in codecs.open(file_path,'r','utf-8'):
    if u'tiers? <exists>' in line and inhibit==0:
        tg_type='long'
        inhibit=1
        continue
    if tg_type=='short':
        if u'"Phonemes"' in line:
            break
        if u'"IntervalTier"' in line:
            cnt2=cnt2+1
            flag=0
            cnt=4
            continue
        if u'"prompt"' in line.lower():
            cnt+=3
        if u'"BACKGROUN' in line or u'"COMMEN' in line:
            break
        if cnt2<1:
            continue
        if cnt>0 and flag==0:
            cnt=cnt-1
            flag=0
            continue
        else:
            flag=1
            cnt=cnt+1
        if cnt%3==1:
            s_time = unicode(str("{:.3f}".format(float(line))))
            s_time_buffer.append(s_time)
            continue
        if cnt%3==2:
            e_time = unicode(str("{:.3f}".format(float(line))))
            e_time_buffer.append(e_time)
            continue
        if cnt%3==0:
            if u'""' in line or '<empty>' in line or '<leeg>' in line:
                print "Skipping file '" + filename + "' cause it contains either one of '<,>,<empty> or <leeg>'..."
                continue
            text=line.replace('\n','').replace('\r\n','').replace('++', '').replace('*d', ''). \
                replace('.', '').replace(',', '').replace('?', '')
            text = u"".join(c for c in text if c not in  (u'!',u'.',u':',u'?',u',',u'\n',u'\r',u'"',u'|',u';',u'(',u')',u'[',u']',u'{',u'}',u'#',u'_',u'+',u'&lt',u'&gt',u'\\'))
            #print "text: " + text.encode('utf8')
            fields = text.lower().split()
            #print "fields: " + str(fields)
            for ele in fields:
                if u'*' in ele or u'xxx' in ele or u'mm' in ele or u'ggg' in ele:
                    ind=fields.index(ele)
                    fields[ind]=u'spn'
                elif u'<opn>' in ele:
                    ind=fields.index(ele)
                    fields[ind]=u'nsn'
            text = u' '.join(fields)
            temp=text.strip().lower().split()
            text = u' '.join(temp)
            text_buffer.append(text)
    else:
        print "Long textgrid format..."
        if u'item [2]' in line:
            break
        if u'intervals [1]:' in line:
            inhibit2=0
        if u'"BACKGROUN' in line or u'"COMMEN' in line:
            break
        if inhibit2==1:
            continue
        if u'intervals [' in line:
            continue
        if u'item [3]' in line:
            break
        if u'xmin' in line:
            fields = line.split('=')
            s_time = str("{:.3f}".format(float(fields[-1][1:-3])))
            s_time_buffer.append(s_time)
            continue
        if u'xmax' in line:
            fields = line.split('=')
            e_time = str("{:.3f}".format(float(fields[-1][1:-3])))
            e_time_buffer.append(e_time)
            continue
        if u'text' in line and (u'text = u""' not in line):
            if u'<' in line or u'>' in line:
               e_time_buffer = e_time_buffer[:-1]
               s_time_buffer = s_time_buffer[:-1]
               continue
            fields = line.split(u'=')
            text = fields[-1]
            text = u"".join(c for c in text if c not in  (u'!',u'.',u':',u'?',u',',u'\n',u'\r',u'"',u'|',u';',u'(',u')',u'[',u']',u'{',u'}',u'#',u'_',u'+',u'&lt',u'&gt',u'\\'))
            temp=text.strip().lower().split()
            text = u' '.join(temp)
            text_buffer.append(text)
"""
text = ' '.join(text_buffer)
#print "textbuffer: " + str(text_buffer)
# louis
print "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy text: " + text.encode("utf8")
if speaker_info=='SA' and text!=u'' and text_buffer!=[]:
    new_wav = new_wav+utt_id+' '+main_folder_wav+'/'+filename+u'\n'
    #new_txt = new_txt+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+' '.join(text_buffer)+u'\n'
    #new_seg = new_seg+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+s_time_buffer[0]+u' '+e_time_buffer[-1]+u'\n'
    #new_utt = new_utt+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+speaker+u'\n'
    new_txt = new_txt+utt_id+u' '+' '.join(text_buffer)+u'\n'
    new_seg = new_seg+utt_id+u' '+utt_id+u' '+s_time_buffer[0]+u' '+e_time_buffer[-1]+u'\n'
    new_utt = new_utt+utt_id+u' '+speaker+u'\n'
    cnt3=cnt3+1
elif speaker_info=='SI' and text!=u'' and text_buffer!=[]:
    new_wav = new_wav+utt_id+' '+main_folder_wav+'/'+filename
    #new_txt = new_txt+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+' '.join(text_buffer)+u'\n'
    #new_seg = new_seg+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+s_time_buffer[0]+u' '+e_time_buffer[-1]+u'\n'
    #new_utt = new_utt+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u' '+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u'\n'
    new_txt = new_txt+utt_id+u' '+' '.join(text_buffer)+u'\n'
    new_seg = new_seg+utt_id+u' '+utt_id+u' '+s_time_buffer[0]+u' '+e_time_buffer[-1]+u'\n'
    new_utt = new_utt+utt_id+u' '+utt_id+u'_'+unicode(str("{:04.0f}".format(cnt3)))+u'\n'
    cnt3=cnt3+1

if cnt3%10==0:
    fid_txt.write(new_txt)
    fid_seg.write(new_seg)
    fid_utt.write(new_utt)
    fid_wav.write(new_wav)
    new_txt = ''
    new_seg = ''
    new_utt = ''
    new_wav = ''

fid_txt.write(new_txt)
fid_seg.write(new_seg)
fid_utt.write(new_utt)
fid_wav.write(new_wav)

fid_txt.close()
fid_seg.close()
fid_utt.close()
fid_wav.close()

lexicon = dict_full.read().encode("utf-8", "ignore")
newlexicon = []

lexicon = lexicon.split("\n")
for words in lexicon:
    words = words.split("\t")
    words = list(words)
    newlexicon.append(words)
newlexicon.pop()

# louis uncommented 
newlexicon = np.asarray(newlexicon, dtype=unicode)

#dict.write(newlexicon[:,0][1] + "\t" + newlexicon[:,1][1] + "\n")
#dictp.write(newlexicon[:,0][1] + "\t" + "1.0" + "\t" + newlexicon[:,1][1] + "\n")


wordset = set()
[wordset.add(word) for word in text.split()]
#print text.encode("utf8", 'ignore')
wordsetc = wordset.copy()

dict.write(u"<SIL>\tSIL\n")
dict.write(spkr_noise_sym + u"\t[SPN]\n")
dict.write(u"<UNK>\t[SPN]\n")
dictp.write(u"<SIL>\t1.0\tSIL\n")
dictp.write(spkr_noise_sym + u"\t1.0\t[SPN]\n")
dictp.write(u"<UNK>\t1.0\t[SPN]\n")

np=0

print "xxxxxxxxxxxxxxxxxxxxxxxxxx"

for word in wordset:
    # louis: added encode("utf8")
    print word.encode("utf8")
    if word not in [spkr_noise_sym, u"<UNK>", u"<SIL>"]:
        found = False
        for dictword in newlexicon:
            np=np+1
            if (np < 10):
                print dictword
            if word == dictword[0]:
                dictline = dictword[0] + "\t" + dictword[1] + "\n"
                dict.write(dictline.encode("utf-8"))
                dictpline = dictword[0] + "\t" + "1.0" + "\t" + dictword[1] + "\n"
                dictp.write(dictpline.encode("utf-8"))
                found = True
                #louis: uncommented next line: keep searching for other matching orthographies
		# break
        if not found:
            #matches = difflib.get_close_matches(word, newlexicon[:,0])
            #for match in matches:
            #    if match not in wordsetc:
            #        wordsetc.add(match)
            #        matchidx = newlexicon[:, 0].tolist().index(match)
            #        dictline = match + "\t" + newlexicon[matchidx][1] + "\n"
            #        dict.write(dictline.encode("utf-8"))
            #        dictpline = match + "\t" + "1.0" + "\t" + newlexicon[matchidx][1] + "\n"
            #        dictp.write(dictpline.encode("utf-8"))
            missing.write(file_path + "\t" + word + "\n".encode("utf-8"))
missing.close()

dict.close()
dictp.close()

os.system('env LC_ALL=C sort -o '+data_folder+'/text'+' '+data_folder+'/text')
os.system('env LC_ALL=C sort -o '+data_folder+'/segments'+' '+data_folder+'/segments')
os.system('env LC_ALL=C sort -u -o  '+data_folder+'/wav.scp'+' '+data_folder+'/wav.scp')
os.system('env LC_ALL=C sort -o '+data_folder+'/utt2spk'+' '+data_folder+'/utt2spk')
os.system('utils/utt2spk_to_spk2utt.pl '+data_folder+'/utt2spk'+' > '+data_folder+'/spk2utt')
