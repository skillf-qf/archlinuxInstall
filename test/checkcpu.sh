#!/bin/bash

cpuinfo=`lscpu | grep "Intel"`

if [ -n "$cpuinfo" ]; then
	echo "cpu is intel"
else
	echo "cpu is amd"
fi
