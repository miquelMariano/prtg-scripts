#!/bin/sh

#DESCRIPTION
#   Check vSphere vSAN resync from ESXi

#NOTES 
#   File Name  : check_vsan_resync.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   Put this script on /var/prtg/scripts and use "SSH Sensor"
#   Command return follow results:
#   [root@esxi:/var/prtg/scripts] esxcli vsan debug resync summary get
#       Total Number Of Resyncing Objects: 0
#       Total Bytes Left To Resync: 0
#       Total GB Left To Resync: 0.00

#   
#CHANGELOG
#   v1 29/08/2019   Script creation
#   

result=$(esxcli vsan debug resync summary get | grep Bytes | awk '{print $6}')

#echo $result

if [ $result == "0" ]; then
  echo "0:$result:$result bytes left to resync"
else
  echo "2:$result:$result bytes left to resync"
fi
