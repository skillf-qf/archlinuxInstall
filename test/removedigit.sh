#!/bin/bash

#str=test22
#echo -e "str=$str\n"
str=$(echo `awk -F "=" '$1=="boot" {print $2}' install.conf` | sed 's/[0-9]*$//')

echo -e "str=$str\n"
