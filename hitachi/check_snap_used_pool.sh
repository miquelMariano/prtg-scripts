#!/bin/bash

#./check_quorum_status.sh 02:00 1

ldev=$1
instance=$2

#raidcom -login maintenance raid-maintenance -I1
#raidcom -login maintenance raid-maintenance -I2

result=$(raidcom get ldev -ldev_id $ldev -I$instance | grep 'Snap_Used_Pool(MB)' |awk '{print $3}')

echo "0:$result:LDEV $ldev Snap_Used_Pool(MB): $result"

