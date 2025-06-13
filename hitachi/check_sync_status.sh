#!/bin/bash

#./check_sync_status.sh 00:07 12

group=$1
LDEV=$2
instance=$3

raidcom -login maintenance raid-maintenance -I$instance

result=$(pairdisplay -g $group -d $group-$LDEV -fxce -l -ITC$instance | grep $group |awk '{print $10}')
output=$(pairdisplay -g $group -d $group-$LDEV -fxce -l -ITC$instance | grep $group)

#echo $result

echo "0:$result:GROUP $1 - LDEV $2 is $result % syncronized | $output"

#if [ $result == "100" ]; then
#  echo "0:$result:PAIR"
#else
#  echo "2:$result:NOT PAIR"
#fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
