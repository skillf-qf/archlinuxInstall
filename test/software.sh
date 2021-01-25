#!/bin/bash


#software=a b c d

ss=`awk -F "=" '$1=="software" {print $2}' install.conf`

for s in $ss; do
	echo -e "$s\n"
done	
