#!/bin/bash

#./check_pool.sh 

instance=$1

#raidcom -login maintenance raid-maintenance -I1
#raidcom -login maintenance raid-maintenance -I2

result=$(raidcom get pool -pool_id 0 -I$instance | grep 000 |awk '{print $3}')

echo "0:$result:Pool usage space %"

#if [ $result == "PAIR" ]; then
#  echo "0:0:LDEV $LDEV is in $result | $output"
#else
#  echo "2:0:LDEV $LDEV is in $result. Not expected result | $output"
#fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
