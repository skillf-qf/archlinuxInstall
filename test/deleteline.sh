#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-28 09:23:43
 # @LastEditTime: 2021-11-14 03:40:20
 # @FilePath: \archlinuxInstall\test\deleteline.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

filename=$1
startline=$2
function deleteline()
# function : Deletes from the beginning of the specified line to the end of the line
# $1 : filename
# $2 : start line for deleteline
{
  	line=`sed -n "/$2/=" $1 | sort -r | tail -1`
 	echo -e "line=$line\n"
  	sed -i "$line"',$d' $1
}
deleteline $filename $startline
