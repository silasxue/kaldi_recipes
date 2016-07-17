#!/bin/bash
# 														EMCS Labs
# 														Hyungwon Yang
# 														hyung8758@gmail.com

# This scripts generate dictionray related parts.
# lexicon, lexiconp, silence, nonsilence, optional_silence, extra_questions


if [ $# -ne 2 ]; then
   echo "Two arguments should be assigned." 
   echo "1. Source data."
   echo "2. The folder generated files saved." && exit 1
fi

# corpus directory: ./krs_data
data=$1
# savining directory: ./data/local/dict
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
for check in lexicon.txt lexiconp.txt silence.txt nonsilence.txt optional_silence.txt extra_questions.txt; do
	if [ -f $save/$check ] && [ ! -z $save/$check ]; then
		echo -e "$check is already present but it will be overwritten."
	fi
done
echo ""
echo ======================================================================

# lexicon.txt and lexiconp.txt
# This file will be written from 'text' file generated from krs_prep_data.sh
# Run this python script by python version 3.
if [ ! -d $save ]; then
	mkdir -p $save
fi
# Just write any name as a saving argument. then it will generate two .txt files.
# ex) $save/egsname; then it will generate > egsname.txt and egsnamep.txt 
python ./local/text2lexicon.py $data $save/lexicon
echo "lexicon.txt and lexiconp.txt files were generated."

# silence.
echo -e "<SIL>\n<UNK>" >  $save/silence_phones.txt
echo "silence.txt file was generated."

# nonsilence.
awk '{$1=""; print $0}' $save/lexicon.txt | tr -s ' ' '\n' | sort -u | sed '/^$/d' >  $save/nonsilence_phones.txt
echo "nonsilence.txt file was generated."

# optional_silence.
echo '<SIL>' >  $save/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
cat $save/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $save/extra_questions.txt || #exit 1;
cat $save/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $save/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."

