#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This script buils Korean ASR model based on kaldi toolkit.
# Before running this script, corpus dataset needs to be divided into 
# two parts: train and test. Allocate datasets such as 'fv01', or 'mv07'
# to train and test folders. This script will detect folder names and 
# extract data features.

# Set path and requisite variables.
# Kaldi root: Where is your kaldi directory?
kaldi=/Users/hyungwonyang/kaldi
# Source data: Where is your source (wavefile) data directory?
source=/Users/hyungwonyang/Documents/data/krs_data
# current directory.
curdir=$PWD

# This step will generate path.sh based on written path above.
. ./local/make_path.sh $kaldi 
. ./cmd.sh
. ./local/code_check.sh $kaldi

# Prepare datasets.
echo "======================================================"
echo "                  data preparation				    "
echo "======================================================"

# Check source file is ready to be used. Does train and test folders exist inside the source folder?
if [ ! -d $source/train -o ! -d $source/test ] ; then
	echo "train and test folders are not present in $source directory." || exit 1
fi

# In each train and test data folder, distribute 'text', 'utt2spk', 'spk2utt', 'wav.scp', 'segments'.
for set in train test; do
	. ./local/krs_prep_data.sh $source/$set $curdir/data/$set || exit 1
done


echo "======================================================"
echo "                 language modeling				    "
echo "======================================================"

# Generate lexicon, lexiconp, silence, nonsilence, optional_silence, extra_questions
# from the train dataset.
. ./local/krs_prep_dict.sh $source/train $curdir/data/local/dict || exit 1

# Insert <UNK> in the lexicon.txt and lexiconp.txt.
sed -i '1 i\<UNK> <UNK>' $curdir/data/local/dict/lexicon.txt
sed -i '1 i\<UNK> 1.0 <UNK>' $curdir/data/local/dict/lexiconp.txt

# Make ./data/lang folder and other files.
utils/prepare_lang.sh $curdir/data/local/dict "<UNK>" $curdir/data/local/lang $curdir/data/lang

# Set ngram-count folder.
nc=`find $KALDI_ROOT/tools/srilm/bin -name ngram-count`
# Make lm.arpa format.
$nc -text ./data/train/textraw -lm ./data/lang/lm.arpa



