#!/bin/bash

#DESCRIPTION
#	Check memory on linux systems

#NOTES 
#	File Name  : meminfo.sh
#	Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#	Version    : 2

#USAGE
#	Put this script on /var/prtg/scripts and use "SSH script"
#	./check_pool_usage.sh <instance>
#	./check_pool_usage.sh 701	
   
#CHANGELOG
#	v1 26/08/2019   Script creation
#	v2 05/11/2019	Add S/N information

instance=$1

#raidcom -login maintenance raid-maintenance -I1
#raidcom -login maintenance raid-maintenance -I2

so_version=$(cat /etc/*-release)

echo "0:0:$so_version"

#logout110=$(raidcom -logout -I1)
#logout108=$(raidcom -logout -I2)
