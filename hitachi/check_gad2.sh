#!/bin/bash

#./check_gad.sh 00:07 12

LDEV=$1

#raidcom -login maintenance raid-maintenance -I$instance

result=$(pairdisplay -g GAD -d $LDEV-$LDEV -fxce -l -ITC5901 | grep GAD |awk '{print $7}')
output=$(pairdisplay -g GAD -d $LDEV-$LDEV -fxce -l -ITC5901 | grep GAD)

#echo $result

if [ $result == "PAIR" ]; then
  echo "0:0:LDEV $LDEV is in $result | $output"
else
  echo "2:0:LDEV $LDEV is in $result. Not expected result | $output"
fi

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
