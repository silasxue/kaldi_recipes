#!/bin/bash

new=("mfcc plp")

declare -a arr=("mfcc" "plp")

for x in ./${new[@]}; do
	echo =====================
	echo $x
done
