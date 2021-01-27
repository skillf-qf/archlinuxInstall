#!/bin/bash

set -euxo pipefail 

set +e
swapstatus=`swapon -s | grep "$swap"`
set -e
if [[ -n "$swap" ]] && [[ ! -n "$swapstatus" ]]; then
       echo "swap off"
else
	echo "swapstatus=$swapstatus"
fi       
