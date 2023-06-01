#!/bin/sh

#DESCRIPTION
#   Check ESXi ntpd status

#NOTES 
#   File Name  : vmware_check_esxi_ntpd.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   - Put this script on /var/prtg/scripts and use "SSH Script"
#	- It's necessary add ssh credentials on device
#   - Command return follow results:
#   [root@esxi:/var/prtg/scripts] esxcli vsan debug resync summary get
#       Total Number Of Resyncing Objects: 0
#       Total Bytes Left To Resync: 0
#       Total GB Left To Resync: 0.00

#   
#CHANGELOG
#   v1 01/06/2023   Script creation


result=$(/etc/init.d/ntpd status)

if [ $result == "ntp is running" ]; then
	echo "0:0:$result"
fi

if [ $result == "ntp is not running" ]; then
	echo "2:0:$result"
fi



