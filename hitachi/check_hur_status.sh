#!/bin/bash

#./check_sync_status.sh 0200 590

LDEV=$1
instance=$2

raidcom -login maintenance raid-maintenance -I$instance

result=$(pairdisplay -g HUR -d HUR-$LDEV -fxce -l -ITC$instance | grep HUR |awk '{print $10}')
output=$(pairdisplay -g HUR -d HUR-$LDEV -fxce -l -ITC$instance | grep HUR)

#echo $result

echo "0:$result:LDEV $1 is $result % syncronized | $output"

#if [ $result == "100" ]; then
#  echo "0:$result:PAIR"
#else
#  echo "2:$result:NOT PAIR"
#fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
