#!/usr/bin/python
# -*- coding: utf-8 -*-

# Sets the end time of the merged manual transcription tier to
# to that of the Kaldi phone tier from the forced alignment. Also
# changes its name to 'transcription'.
#
# Created on 2016-12-15 by Mario Ganzeboom

import sys, os, os.path, wave
from praat import textgrid

if len(sys.argv) > 1 and sys.argv[1] != "":
    target_dir = sys.argv[1]
    ext = "_aligned.tg"

    for file_name in os.listdir(target_dir):
        if file_name.endswith(ext):
	    textgrid_file = textgrid.Textgrid()
            print(os.path.join(target_dir, file_name))
	    textgrid_file.read(os.path.join(target_dir, file_name))
	    phone_tier = textgrid_file.get_tier_by_name("kaldiphone")
            duration = -1.0
            if phone_tier == None:
                # Get duration from wave file (more expensive in computation though)
                f = wave.open(os.path.join(target_dir, file_name[:-len(ext)]+".wav"),'r')
                frames = f.getnframes()
                rate = f.getframerate()
                duration = frames / float(rate)
            else:
                duration = phone_tier.etime
            textgrid_file.etime = duration
            man_trans_tier = textgrid_file.get_tier_by_name("Words")
            if man_trans_tier != None:
                man_trans_tier.name = "transcription"
                man_trans_tier.etime = duration
                man_trans_tier.intervals[0].etime = duration

            prompt_tier = textgrid_file.get_tier_by_name("prompt")
            if prompt_tier != None:
                prompt_tier.etime = duration
                prompt_tier.intervals[0].etime = duration
            textgrid_file.write_short(os.path.join(target_dir, file_name))
else:
    print("Syntax error: This script requires 1 argument that points to the target dir. containing the merged textgrids.\nAborting...")
    sys.exit(1)

