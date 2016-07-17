#!/bin/bash

# first 
mono_opt='--boost-silence 1.25 --nj 2 --cmd $train_cmd'
steps/train_mono.sh $mono_opt $curdir/data/train $curdir/data/lang $curdir/exp/mono

# second

steps/train_mono.sh --boost-silence 1.25 --nj 2 --cmd $train_cmd $curdir/data/train $curdir/data/lang $curdir/exp/mono