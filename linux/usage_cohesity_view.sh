#!/bin/bash
#
#DESCRIPTION
#   Monitor usage of cohesity view using listViews.py python script
#
#NOTES 
#   File Name  : usage_cohesity_view.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1
#
#USAGE
#   Put this script on /var/prtg/scriptsxml and use "SSH script advanced sensor XML"
#   ./usage_cohesity_view.sh view_name gib cohesity.corp.local miquel.mariano corp.local
#
#REQUISITES
#   This script need listViews.py see https://github.com/bseltz-cohesity/scripts/tree/b445a612dd472f1db5126c763b0f66a072d4a2f1/python/listViews	
#CHANGELOG
#   v1 21/12/2021   Script creation
#

cohesity_view_name=$1
units=$2 #mib or gib
vip=$3
user=$4
domain=$5

logical_usage=$(/etc/scripts-cohesity/listViews/listViews.py -v $3 -u $4 -d $5 -s -n $1 -x $2 | grep 'logical usage' |awk '{print $3}' |cut -d . -f 1)
logical_quota=$(/etc/scripts-cohesity/listViews/listViews.py -v $3  -u $4 -d $5 -s -n $1 -x $2 | grep 'logical quota' |awk '{print $3}')
quota_alert=$(/etc/scripts-cohesity/listViews/listViews.py -v $3  -u $4 -d $5 -s -n $1 -x $2 | grep 'quota alert' |awk '{print $3}')

usage=$(($logical_usage * 100/$logical_quota))

xmlresult=`cat <<EOF
<?xml version="1.0" encoding='UTF-8'?>
<prtg>
<text> Cohesity statistics for view: $1</text>
  <result>
    <channel>Usage</channel>
    <unit>Percent</unit>
    <value>$usage</value>
    <LimitMaxError>90</LimitMaxError>
    <LimitMaxWarning>80</LimitMaxWarning>
    <LimitMode>1</LimitMode>
  </result>
  <result>
    <channel>Logical Usage</channel>
    <unit>Custom</unit>
    <customUnit>$2</customUnit>
    <value>$logical_usage</value>
  </result>
  <result>
    <channel>Logical Quota</channel>
    <unit>Custom</unit>
    <customUnit>$2</customUnit>
    <value>$logical_quota</value>
  </result>
  <result>
    <channel>Quota alert</channel>
    <unit>Custom</unit>
    <customUnit>$2</customUnit>
    <value>$quota_alert</value>
  </result>
</prtg>

EOF
`

echo "$xmlresult"

exit 0
