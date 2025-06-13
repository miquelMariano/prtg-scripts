#!/bin/bash

#./check_sync_status.sh 0200 590

instance=$1
LDEV=$2
snap_name=$3
ldev_size=$4

raidcom -login maintenance raid-maintenance -I$instance

result=$(raidcom get snapshot -ldev_id $LDEV -fx -format_time -I$instance| grep $snap_name |awk '{print $9}')
output=$(raidcom get snapshot -ldev_id $LDEV -fx -format_time -I$instance| grep $snap_name)

#echo $result

sync_size=$(($result*$ldev_size/100))
snap_size=`expr $ldev_size - $sync_size`

echo "0:$snap_size:Snap $LDEV_ $snap_name size is $snap_size GB ($result % syncronized) | $output"

#if [ $result == "100" ]; then
#  echo "0:$result:PAIR"
#else
#  echo "2:$result:NOT PAIR"
#fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
