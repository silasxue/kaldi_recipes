#!/bin/bash

# This script buils Korean ASR model based on kaldi toolkit.
# 


# Set path and requisite variables.
# Kaldi root: Where is your kaldi directory?
kaldi=/Users/hyungwonyang/kaldi
# Source data: Where is your source (wavefile) data directory?
data=/Users/hyungwonyang/Documents/data/krs_data

. ./path.sh $kaldi $data
. ./cmd.sh

# Prepare datasets.
echo "======================================================"
echo "					 data preparation				    "
echo "======================================================"

# Generate text, utt2spk, wav.scp, segments.
curdir=$PWD
. ./local/krs_prep_data.sh $curdir/krs_data $curdir/data/local/data
# . test.sh $cur_dir/krs_data $cur_dir/data/train

# Distribute the components to train and test folders.: text, utt2spk, spk2utt, wav.scp
mkdir -p ./data/test


# Generate lexicon, lexiconp, silence, nonsilence, optional_silence, extra_questions.
. ./local/krs_prep_dict.sh $curdir/krs_data $curdir/data/local/dict
# . test.sh $cur_dir/krs_data $cur_dir/data/train

# Insert <UNK> in the lexicon.txt and lexiconp.txt.
sed -i '1 i\<UNK>\t<UNK>' $curdir/data/local/dict/lexicon.txt
sed -i '1 i\<UNK>\t<UNK>' $curdir/data/local/dict/lexiconp.txt

# 
utils/prepare_lang.sh $curdir/data/local/dict "<UNK>" $curdir/data/local/lang $curdir/data/lang


