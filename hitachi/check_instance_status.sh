#!/bin/bash

# ./check_instance_status.sh 3

ps_out=`ps -ef | grep horcmd_0$1 | grep -v 'grep' | grep -v $0`

result=$(echo $ps_out | grep "$1")


if [[ "$result" != "" ]];then
    echo "0:0:Instance horcmd_0$1 is running"
else
    echo "2:0:Instance horcmd_0$1 not Running"
fi


