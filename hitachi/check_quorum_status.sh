#!/bin/bash

#./check_quorum_status.sh 02:00 1

ldev=$1
instance=$2

#raidcom -login maintenance raid-maintenance -I1
#raidcom -login maintenance raid-maintenance -I2

result=$(raidcom get ldev -ldev_id $ldev -I$instance | grep STS |awk '{print $3}')

if [ $result == "NML" ]; then
  echo "0:0:LDEV $ldev is $result status"
else
  echo "2:0:LDEV $ldev is $result status. Not expected result"
fi


#if [ $result == "PAIR" ]; then
#  echo "0:0:LDEV $LDEV is in $result | $output"
#else
#  echo "2:0:LDEV $LDEV is in $result. Not expected result | $output"
#fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
