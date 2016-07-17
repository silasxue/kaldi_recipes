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
# In the source directory, datasets should be assigned in two directories: train, and test.
source=/Users/hyungwonyang/Documents/data/krs_data
# Log file: Log file will be saved with the name set below.
logfile=1st_test
# current directory.
curdir=$PWD

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


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                    Train & Decode: Monophone	                 	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start4=`date +%s`; log_s4=`date | awk '{print $4}'`
echo $log_s4 >> $logdir/$logfile.log 
echo START TIME: $log_s4 | tee -a $logdir/$logfile.log 

# Monophone option setting.
mono_train_opt="--boost-silence 1.25 --nj 2 --cmd $train_cmd"
mono_decode_opt="--nj $train_nj --cmd $decode_cmd"
echo "Monophone trainig options: $mono_train_opt"
echo "Monophone decoding options: $mono_decode_opt"

# Monophone train.
steps/train_mono.sh $mono_train_opt $curdir/data/train $curdir/data/lang $curdir/exp/mono ||  exit1

# Graph structuring.
# make HCLG graph (optional! train과는 무관, 오직 decode만을 위해.)
# This script creates a fully expanded decoding graph (HCLG) that represents
# all the language-model, pronunciation dictionary (lexicon), context-dependency,
# and HMM structure in our model.  The output is a Finite State Transducer
# that has word-ids on the output, and pdf-ids on the input (these are indexes
# that resolve to Gaussian Mixture Models).
# exp/mono/graph에 가면 결과 graph가 만들어져 있음
utils/mkgraph.sh $curdir/data/lang $curdir/exp/mono $curdir/exp/mono/graph 

# Monophone aglinment.
# train된 model파일인 mdl과 occs로부터 새로운 align을 생성
steps/align_si.sh $mono_decode_opt $curdir/data/train $curdir/data/lang $curdir/exp/mono $curdir/exp/mono_ali || exit 1

### Optional ###
# Data decoding.
# (This is just decoding the trained model, not part of training process.)
steps/decode.sh $mono_decode_opt $curdir/exp/mono/graph $curdir/data/train $curdir/exp/mono/decode_train

# tree structuring.
$KALDI_ROOT/src/bin/draw-tree $curdir/data/lang/phones.txt $curdir/exp/mono/tree \
| dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf 2>/dev/null


end4=`date +%s`; log_e4=`date | awk '{print $4}'`
taken4=`. $curdir/local/track_time.sh $start4 $end4`
echo END TIME: $log_e4  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken4 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "           Train & Decode: Triphone1 [delta+delta-delta]	       	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start5=`date +%s`; log_s5=`date | awk '{print $4}'`
echo $log_s5 >> $logdir/$logfile.log 
echo START TIME: $log_s5 | tee -a $logdir/$logfile.log 

# Triphone1 option setting.
tri1_trian_opt="--cmd $train_cmd"
tri1_decode_opt="--nj $train_nj --cmd $decode_cmd"
echo "Triphone1 trainig options: $tri1_train_opt"
echo "Tirphone1 decoding options: $tir1_decode_opt"

# Triphone1 training.
steps/train_deltas.sh $tri1_train_opt 2000 10000 $curdir/data/train $curdir/data/lang $curdir/exp/mono_ali $curdir/exp/tri1

# Graph drawing.
utils/mkgraph.sh $curdir/data/lang $curdir/exp/tri1 $curdir/exp/tri1/graph

# Triphone1 aglining.
steps/align_si.sh $tri1_decode_opt $curdir/data/train $curdir/data/lang $curdir/exp/tri1 $curdir/exp/tri1_ali

# Data decoding.
steps/decode.sh $tri1_decode_opt $curdir/exp/tri1/graph $curdir/data/train $curdir/exp/tri1/decode_train


end5=`date +%s`; log_e5=`date | awk '{print $4}'`
taken5=`. $curdir/local/track_time.sh $start5 $end5`
echo END TIME: $log_e5  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken5 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "               Train & Decode: Triphone2 [LDA+MLLT]	         	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start6=`date +%s`; log_s6=`date | awk '{print $4}'`
echo $log_s6 >> $logdir/$logfile.log 
echo START TIME: $log_s6 | tee -a $logdir/$logfile.log 

# Triphone2 option setting.
tri2_trian_opt="--cmd $train_cmd"
tri2_decode_opt="--nj $train_nj --cmd $decode_cmd"
echo "Triphone2 trainig options: $tri2_train_opt"
echo "Tirphone2 decoding options: $tir2_decode_opt"

# Triphone2 training.
steps/train_lda_mllt.sh tri2_trian_opt 2500 15000 $curdir/data/train $curdir/data/lang $curdir/exp/tri1_ali $curdir/exp/tri2

# Graph drawing.
utils/mkgraph.sh $curdir/data/lang $curdir/exp/tri2 $curdir/exp/tri2/graph

# Triphone2 aglining.
steps/align_si.sh $tri2_decode_opt $curdir/data/train $curdir/data/lang $curdir/exp/tri2 $curdir/exp/tri2_ali

# Data decoding.
steps/decode.sh $tri2_decode_opt $curdir/exp/tri2/graph $curdir/data/train $curdir/exp/tri2/decode_train


end6=`date +%s`; log_e6=`date | awk '{print $4}'`
taken6=`. $curdir/local/track_time.sh $start6 $end6`
echo END TIME: $log_e6  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken6 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "             Train & Decode: Triphone3 [LDA+MLLT+SAT]	         	  " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start7=`date +%s`; log_s7=`date | awk '{print $4}'`
echo $log_s7 >> $logdir/$logfile.log 
echo START TIME: $log_s7 | tee -a $logdir/$logfile.log 

# Triphone3 option setting.
tri3_trian_opt="--cmd $train_cmd"
tri3_decode_opt="--nj $train_nj --cmd $decode_cmd"
echo "Triphone3 trainig options: $tri3_train_opt"
echo "Tirphone3 decoding options: $tir3_decode_opt"

# Triphone3 training.
steps/train_sat.sh $tri3_train_opt 2500 15000 $curdir/data/train $curdir/data/lang $curdir/exp/tri2_ali $curdir/exp/tri3

# Graph drawing.
utils/mkgraph.sh $curdir/data/lang $curdir/exp/tri3 $curdir/exp/tri3/graph

# Triphone3 aglining.
steps/align_fmllr.sh $tri3_decode_opt $curdir/data/train $curdir/data/lang $curdir/exp/tri3 $curdir/exp/tri3_ali

# Data decoding: train dataset.
steps/decode_fmllr.sh $tri3_decode_opt $curdir/exp/tri3/graph $curdir/data/train $curdir/exp/tri3/decode_train
# Data decoding: test dataset.
steps/decode_fmllr.sh $tri3_decode_opt $curdir/exp/tri3/graph $curdir/data/test $curdir/exp/tri3/decode_test


end7=`date +%s`; log_e7=`date | awk '{print $4}'`
taken7=`. $curdir/local/track_time.sh $start7 $end7`
echo END TIME: $log_e7  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken7 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                       Train & Decode: SGMM2 	               	      " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start8=`date +%s`; log_s8=`date | awk '{print $4}'`
echo $log_s8 >> $logdir/$logfile.log 
echo START TIME: $log_s8 | tee -a $logdir/$logfile.log 

# SGMM training, with speaker vectors.  This script would normally be called on
# top of fMLLR features obtained from a conventional system, but it also works
# on top of any type of speaker-independent features (based on
# deltas+delta-deltas or LDA+MLLT).  For more info on SGMMs, see the paper "The
# subspace Gaussian mixture model--A structured model for speech recognition".
# (Computer Speech and Language, 2011).

# SGMM2 option setting.
sgmm2_trian_opt="--cmd $train_cmd"
sgmm2_decode_opt="--nj $train_nj --cmd $decode_cmd --transform-dir"
echo "SGMM2 trainig options: $sgmm2_train_opt"
echo "SGMM2 decoding options: $sgmm2_decode_opt"

# UBM training.
steps/train_ubm.sh 400 $curdir/data/train $curdir/data/lang $curdir/exp/tri3_ali $curdir/exp/ubm

# SGMM2 training.
steps/train_sgmm2.sh $sgmm2_train_opt 5000 8000 $curdir/data/train $curdir/data/lang $curdir/exp/tri3_ali $curdir/exp/ubm/final.ubm $curdir/exp/sgmm

# Graph drawing.
utils/mkgraph.sh $curdir/data/lang $curdir/exp/sgmm $curdir/exp/sgmm/graph

# SGMM2 aglining.
steps/align_sgmm2.sh $sgmm2_train_opt --transform-dir $curdir/exp/tri3_ali $curdir/data/train $curdir/data/lang $curdir/exp/sgmm $curdir/exp/sgmm_ali

# Data decoding: train dataset.
steps/decode_sgmm2.sh -$sgmm2_decode_opt $curdir/exp/tri3_ali $curdir/exp/sgmm/graph $curdir/data/train $curdir/exp/sgmm/decode_train

# Data decoding: test dataset.
steps/decode_sgmm2.sh $sgmm2_decode_opt $curdir/exp/tri3/decode_test $curdir/exp/sgmm/graph $curdir/data/test $curdir/exp/sgmm/decode_test


end8=`date +%s`; log_e8=`date | awk '{print $4}'`
taken8=`. $curdir/local/track_time.sh $start8 $end8`
echo END TIME: $log_e8  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken8 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                     Train & Decode: SGMM2+MMI 	           	      " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start9=`date +%s`; log_s9=`date | awk '{print $4}'`
echo $log_s9 >> $logdir/$logfile.log 
echo START TIME: $log_s9 | tee -a $logdir/$logfile.log 

# SGMM training, with speaker vectors.  This script would normally be called on
# top of fMLLR features obtained from a conventional system, but it also works
# on top of any type of speaker-independent features (based on
# deltas+delta-deltas or LDA+MLLT).  For more info on SGMMs, see the paper "The
# subspace Gaussian mixture model--A structured model for speech recognition".
# (Computer Speech and Language, 2011).

# SGMM2 option setting.
sgmmi_trian_opt="--cmd $train_cmd"
sgmmi_decode_opt="--transform-dir"
echo "SGMM2+MMI trainig options: $sgmmi_train_opt"
echo "SGMM2+MMI decoding options: $sgmmi_decode_opt"

# SGMM2+MMI training.
steps/make_denlats_sgmm2.sh --nj "$train_nj" --sub-split 40 --transform-dir $curdir/exp/tri3_ali $curdir/data/train $curdir/data/lang $curdir/exp/sgmm_ali $curdir/exp/sgmm_denlats
steps/train_mmi_sgmm2.sh $sgmmi_train_opt $curdir/exp/tri3_ali $curdir/data/train $curdir/data/lang $curdir/exp/sgmm_ali $curdir/exp/sgmm_denlats $curdir/exp/sgmm_mmi

# Data decoding: train dataset.
steps/decode_sgmm2_rescore.sh $sgmmi_decode_opt $curdir/exp/tri3/decode_train $curdir/data/lang $curdir/data/train $curdir/exp/sgmm/decode_train $curdir/exp/sgmm_mmi/decode_train

# Data decoding: test dataset.
steps/decode_sgmm2_rescore.sh $sgmmi_decode_opt $curdir/exp/tri3/decode_test $curdir/data/lang $curdir/data/test $curdir/exp/sgmm/decode_test $curdir/exp/sgmm_mmi/decode_test


end9=`date +%s`; log_e9=`date | awk '{print $4}'`
taken9=`. $curdir/local/track_time.sh $start9 $end9`
echo END TIME: $log_e9  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken9 sec  | tee -a $logdir/$logfile.log


echo ====================================================================== | tee -a $logdir/$logfile.log 
echo "                       Train & Decode: DNN  	            	      " | tee -a $logdir/$logfile.log 
echo ====================================================================== | tee -a $logdir/$logfile.log 
start10=`date +%s`; log_s10=`date | awk '{print $4}'`
echo $log_s10 >> $logdir/$logfile.log 
echo START TIME: $log_s10 | tee -a $logdir/$logfile.log 

# SGMM training, with speaker vectors.  This script would normally be called on
# top of fMLLR features obtained from a conventional system, but it also works
# on top of any type of speaker-independent features (based on
# deltas+delta-deltas or LDA+MLLT).  For more info on SGMMs, see the paper "The
# subspace Gaussian mixture model--A structured model for speech recognition".
# (Computer Speech and Language, 2011).

# SGMM2 option setting.
dnn1_trian_opt=""
dnn1_decode_opt="--nj $train_nj --transform-dir"
dnn_function:"train_tanh_fast.sh"
echo "DNN($dnn_function) trainig options: $dnn1_train_opt"
echo "DNN($dnn_function) decoding options: $dnn1_decode_opt"

# DNN training.
# train_tanh_fast.sh
steps/nnet2/train_tanh_fast.sh $dnn1_train_opt $curdir/data/train $curdir/data/lang $curdir/exp/tri3_ali $curdir/exp/tri4
# train_multisplice_accel2.sh

# train_tdnn.sh


# Data decoding: train dataset.
steps/nnet2/decode.sh $dnn1_decode_opt $curdir/exp/tri3/decode_train $curdir/exp/tri3/graph $curdir/data/train $curdir/exp/tri4/decode_train

# Data decoding: test dataset.
steps/nnet2/decode.sh $dnn1_decode_opt $curdir/exp/tri3/decode_test $curdir/exp/tri3/graph $curdir/data/test $curdir/exp/tri4/decode_test


end10=`date +%s`; log_e10=`date | awk '{print $4}'`
taken10=`. $curdir/local/track_time.sh $start10 $end10`
echo END TIME: $log_e10  | tee -a $logdir/$logfile.log 
echo PROCESS TIME: $taken10 sec  | tee -a $logdir/$logfile.log







##########################################################
# This is for final log.
END=`date +%s`
end5=`. $curdir/local/track_time.sh $start5 $end5`
taken=`. $curdir/local/track_time.sh $STRAT $END`
echo END TIME: $end5  | tee -a $logdir/$logfile.log 
echo TOTAL TIME: $taken sec  | tee -a $logdir/$logfile.log 

