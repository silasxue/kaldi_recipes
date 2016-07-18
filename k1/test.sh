#!/bin/bash

new1=string
new2=nice

for box in new1 new2; do
	echo ${!box}
done
