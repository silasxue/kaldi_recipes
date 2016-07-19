#!/bin/bash

# This script will run the monophone training under the 6 different conditions.
# There are 3 variables: transition scale, acoustic scale, and self-loop scale.
# 1.  1  / 0.1 / 0.1
# 2.  1  /  1  / 0.1
# 3.  1  / 0.1 /  1
# 4.  1  /  1  /  1
# 5. 0.1 /  1  / 0.1
# 6. 0.1 /  1  /  1
# 7. 0.1 / 0.1 /  1
# 8. 0.1 / 0.1 / 0.1

opt1="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1"
opt2="--transition-scale=1.0 --acoustic-scale=1.0 --self-loop-scale=0.1"
opt3="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=1.0"
opt4="--transition-scale=1.0 --acoustic-scale=1.0 --self-loop-scale=1.0"
opt5="--transition-scale=0.1 --acoustic-scale=1.0 --self-loop-scale=0.1"
opt6="--transition-scale=0.1 --acoustic-scale=1.0 --self-loop-scale=1.0"
opt7="--transition-scale=0.1 --acoustic-scale=0.1 --self-loop-scale=1.0"
opt8="--transition-scale=0.1 --acoustic-scale=0.1 --self-loop-scale=0.1"

# Set path and requisite variables.
# Kaldi root: Where is your kaldi directory?
kaldi=/Users/hyungwonyang/kaldi
# Source data: Where is your source (wavefile) data directory?
# In the source directory, datasets should be assigned in two directories: train, and test.
source=/Users/hyungwonyang/Documents/data/krs_data
# Log file: Log file will be saved with the name set below.
logfile=1st_test
# current directory.
curdir=$PWD
# Number of jobs.
nj=2


# Start logging.
mkdir -p $curdir/log
logdir=$curdir/log
echo ====================================================================== | tee $logdir/$logfile.log
echo "                       Kaldi ASR Project	                		  " | tee -a $logdir/$logfile.log
echo ====================================================================== | tee -a $logdir/$logfile.log
echo Tracking the training procedure on: `date` | tee -a $logdir/$logfile.log
echo KALDI_ROOT: $kaldi | tee -a $logdir/$logfile.log
echo DATA_ROOT: $source | tee -a $logdir/$logfile.log
START=`date +%s`

# This step will generate path.sh based on written path above.
. ./local/make_path.sh $kaldi 
. ./cmd.sh
. ./local/check_code.sh $kaldi


echo ====================================================================== | tee -a $logdir/$logfile.log
echo "                       Data Preparation	                		  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start1=`date +%s`; log_s1=`date | awk '{print $4}'`
echo $log_s1 >> $logdir/$logfile.log 
echo START TIME: $log_s1 | tee -a $logdir/$logfile.log 

# Check source file is ready to be used. Does train and test folders exist inside the source folder?
if [ ! -d $source/train -o ! -d $source/test ] ; then
	echo "train and test folders are not present in $source directory." || exit 1
fi

# In each train and test data folder, distribute 'text', 'utt2spk', 'spk2utt', 'wav.scp', 'segments'.
for set in train test; do
	. ./local/krs_prep_data.sh $source/$set $curdir/data/$set || exit 1
done


end1=`date +%s`; log_e1=`date | awk '{print $4}'`
taken1=`. $curdir/local/track_time.sh $start1 $end1`
echo END TIME: $log_e1  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken1 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                       Language Modeling	                		  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start2=`date +%s`; log_s2=`date | awk '{print $4}'`
echo $log_s2 >> $logdir/$logfile.log 
echo START TIME: $log_s2 | tee -a $logdir/$logfile.log 

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
# Make lm.arpa from textraw.
$nc -text $curdir/data/train/textraw -lm $curdir/data/lang/lm.arpa

# Make G.fst from lm.arpa.
cat $curdir/data/lang/lm.arpa | $KALDI_ROOT/src/lmbin/arpa2fst --disambig-symbol=#0 --read-symbol-table=$curdir/data/lang/words.txt - $curdir/data/lang/G.fst
# Check .fst is stochastic or not.
$KALDI_ROOT/src/fstbin/fstisstochastic $curdir/data/lang/G.fst


end2=`date +%s`; log_e2=`date | awk '{print $4}'`
taken2=`. $curdir/local/track_time.sh $start2 $end2`
echo END TIME: $log_e2  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken2 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                   Acoustic Feature Extraction	             	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start3=`date +%s`; log_s3=`date | awk '{print $4}'`
echo $log_s3 >> $logdir/$logfile.log 
echo START TIME: $log_s3 | tee -a $logdir/$logfile.log 

### MFCC ###
# Generate mfcc configure.
mkdir -p $curdir/conf
echo -e '--use-energy=false\n--sample-frequency=16000' > $curdir/conf/mfcc.conf
# mfcc feature extraction.
mfccdir=mfcc
steps/make_mfcc.sh $curdir/data/train $curdir/exp/make_mfcc/train $mfccdir
# Compute cvnm. (This steps should be processed right after mfcc features are extracted.)
steps/compute_cmvn_stats.sh $curdir/data/train $curdir/exp/make_mfcc/train $curdir/$mfccdir

### PLP ###
echo -e '--sample-frequency=16000' > $curdir/conf/plp.conf
plpdir=plp
steps/make_plp.sh $curdir/data/train $curdir/exp/make_plp/train $curdir/$plpdir
# Compute cvnm. (This steps should be processed right after plp features are extracted.)
steps/compute_cmvn_stats.sh $curdir/data/train $curdir/exp/make_plp/train $curdir/$plpdir

# data directories sanity check.
utils/validate_data_dir.sh data/train
utils/fix_data_dir.sh data/train


end3=`date +%s`; log_e3=`date | awk '{print $4}'`
taken3=`. $curdir/local/track_time.sh $start3 $end3`
echo END TIME: $log_e3  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken3 sec  | tee -a $logdir/$logfile.log


for times in opt1 opt2 opt3 opt4 opt5 opt6 opt7 opt8; do

	curopt=`echo ${!times}` 
	echo "Trials: $times"
	echo "Options: $curopt"
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	echo "                    Train & Decode: Monophone	                 	  " | tee -a $logdir/$logfile.log 
	echo ====================================================================== | tee -a $logdir/$logfile.log 
	start4=`date +%s`; log_s4=`date | awk '{print $4}'`
	echo $log_s4 >> $logdir/$logfile.log 
	echo START TIME: $log_s4 | tee -a $logdir/$logfile.log 

	# Monophone option setting.
	mono_train_opt="--boost-silence 1.25 --nj $nj --cmd $train_cmd "$curopt
	mono_decode_opt="--nj $nj --cmd $decode_cmd"
	echo "Monophone trainig options: $mono_train_opt"
	echo "Monophone decoding options: $mono_decode_opt"

	# Monophone train.
	steps/train_mono.sh $mono_train_opt $curdir/data/train $curdir/data/lang $curdir/exp/mono ||  exit1

	#utils/mkgraph.sh $curdir/data/lang $curdir/exp/mono $curdir/exp/mono/graph 

	# Monophone aglinment.
	# train된 model파일인 mdl과 occs로부터 새로운 align을 생성
	steps/align_si.sh $mono_decode_opt $curdir/data/train $curdir/data/lang $curdir/exp/mono $curdir/exp/mono_ali || exit 1

	### Optional ###
	# Data decoding.
	# (This is just decoding the trained model, not part of training process.)
	steps/decode.sh $mono_decode_opt $curdir/exp/mono/graph $curdir/data/train $curdir/exp/mono/decode_$times

	end4=`date +%s`; log_e4=`date | awk '{print $4}'`
	taken4=`. $curdir/local/track_time.sh $start4 $end4`
	echo END TIME: $log_e4  | tee -a $logdir/$logfile.log 
	echo PROCESS TIME: $taken4 sec  | tee -a $logdir/$logfile.log
done

# This is for final log.
END=`date +%s`
taken=`. $curdir/local/track_time.sh $STRAT $END`
echo TOTAL TIME: $taken sec  | tee -a $logdir/$logfile.log 

