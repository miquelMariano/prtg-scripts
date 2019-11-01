#!/bin/bash

#./check_sync_status.sh 00:07 12

LDEV=$1
instance=$2

raidcom -login maintenance raid-maintenance -I$instance

result=$(pairdisplay -g GAD -d $LDEV-$LDEV -fxce -l -ITC$instance | grep GAD |awk '{print $10}')
output=$(pairdisplay -g GAD -d $LDEV-$LDEV -fxce -l -ITC$instance | grep GAD)

#echo $result

echo "0:$result:LDEV $1 is $result % syncronized | $output"

#if [ $result == "100" ]; then
#  echo "0:$result:PAIR"
#else
#  echo "2:$result:NOT PAIR"
#fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
