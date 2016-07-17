#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This scripts generate prerequsite datasets.
# text, utt2spk, wav.scp, segments.

# ./data/local/data => text, utt2spk, wav.scp, segments, glm, stm
# ./conf => phones.60-48-39.map 
# ./local/dict => lexicon.txt
# ./wavtxt => raw wav와 txt 파일

if [ $# -ne 2 ]; then
   echo "Two arguments should be assigned." 
   echo "1. Source data."
   echo "2. The folder generated files saved." && exit 1
fi

# Corpus directory: ./krs_data
data=$1
# Result directory: ./data/local/data
save=$2

echo ======================================================================
echo "                              NOTICE                                "
echo ""
echo "CURRENT SHELL: $0"
echo -e "INPUT ARGUMENTS:\n$@"

# requirement check
if [ ! -d $data ]; then
	echo "Corpus data is not present." && exit 1
	echo ""
	echo ======================================================================
fi
for check in text utt2spk spk2utt wav.scp segments glm stm ; do
	if [ -f $save/$check ] && [ ! -z $save/$check ]; then
		echo -e "$check is already present but it will be overwritten."
	fi
done
echo ""
echo ======================================================================

# text
if [ ! -d $save ]; then
	mkdir -p $save
fi

if [ -f $save/text ] && [ ! -z $save/text ]; then
	echo '' > $save/text
	echo '* Previous text file was removed.'

	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			tmp1=`echo $get_snt | sed 's/\.TextGrid//g'`
			tmp2=`cat $data/$data_name/$get_snt | sed '1,/"word"/d' | grep '"' | egrep -v "sil|sp" | sed "s/\"//" | sed "s/\"//" | \
			tr -s '\n' ' '`
			echo "$tmp1 $tmp2" >> $save/text || exit 1
		done
	done
	sed '1d' $save/text > $save/tmp; cat $save/tmp > $save/text; rm $save/tmp

else
	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			tmp1=`echo $get_snt | sed 's/\.TextGrid//g'`
			tmp2=`cat $data/$data_name/$get_snt | sed '1,/"word"/d' | grep '"' | egrep -v "sil|sp" | sed "s/\"//" | sed "s/\"//" | \
			tr -s '\n' ' '`
			echo "$tmp1 $tmp2" >> $save/text || exit 1
		done
	done
fi
echo "text file was generated."

# textraw
cat $save/text | awk '{$1=""; print $0}' $save/text | sed 's/^ *//' > $save/textraw || exit 1
echo "textraw file was generated."

# utt2spk
if [ -f $save/utt2spk ] && [ ! -z $save/utt2spk ]; then
	echo '' > $save/utt2spk
	echo '* Previous utt2spk file was removed.'

	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			tmp1=`echo $get_snt | sed 's/\.TextGrid//g'`
			echo "$tmp1 $data_name" >> $save/utt2spk || exit 1
		done
	done
	sed '1d' $save/utt2spk > $save/tmp; cat $save/tmp > $save/utt2spk; rm $save/tmp

else
	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do

			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			tmp1=`echo $get_snt | sed 's/\.TextGrid//g'`
			echo "$tmp1 $data_name" >> $save/utt2spk || exit 1
		done
	done
fi

# Make a spk2utt file.
utils/utt2spk_to_spk2utt.pl $save/utt2spk > $save/spk2utt || exit 1
echo "utt2spk and spk2utt files were generated."

# wav.scp
if [ -f $save/wav.scp ] && [ ! -z $save/wav.scp ]; then
	echo '' > $save/wav.scp
	echo '* Previous wav.scp file was removed.'

	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep .wav`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			wav_snt=`echo $get_snt | sed 's/.wav//g'`
			echo "$wav_snt $data/$data_name/$get_snt" >> $save/wav.scp || exit 1
		done
	done
	sed '1d' $save/wav.scp > $save/tmp; cat $save/tmp > $save/wav.scp; rm $save/tmp

else
	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep .wav`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			wav_snt=`echo $get_snt | sed 's/.wav//g'`
			echo "$wav_snt $data/$data_name/$get_snt" >> $save/wav.scp || exit 1
		done
	done
fi
echo "wav.scp file was generated."

# segments
# Each sound dataset contains only one sentence. Therefore, segement information is not needed. 
# However, this script will generate segements file.
if [ -f $save/segments ] && [ ! -z $save/segments ]; then
	echo '' > $save/segments
	echo '* Previous segments file was removed.'

	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep .TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			wav_snt=`echo $get_snt | sed 's/.TextGrid//g'`
			time1=`cat $data/$data_name/$get_snt | sed '1,/"word"/d' | sed -n '1p'`
			time2=`cat $data/$data_name/$get_snt | sed '1,/"word"/d' | sed -n '2p'`
			echo "$wav_snt $wav_snt $time1 $time2" >> $save/segments || exit 1
		done
	done
	sed '1d' $save/segments > $save/tmp; cat $save/tmp > $save/segments; rm $save/tmp

else
	data_num=`ls $data | wc -w`
	data_list=`ls $data`

	for txt in `seq 1 $data_num`; do
		data_name=`echo $data_list | cut -d' ' -f$txt`
		snt_list=`ls $data/$data_name | grep .TextGrid`
		snt_num=`echo $snt_list | wc -w`

		for snt in `seq 1 $snt_num`; do
			get_snt=`echo $snt_list | cut -d' ' -f$snt`
			wav_snt=`echo $get_snt | sed 's/.TextGrid//g'`
			time1=`cat $data/$data_name/$get_snt | sed '1,/"word"/d' | sed -n '1p'`
			time2=`cat $data/$data_name/$get_snt | sed '1,/"word"/d' | sed -n '2p'`
			echo "$wav_snt $wav_snt $time1 $time2" >> $save/segments || exit 1
		done
	done
fi
echo "segments file was generated."
