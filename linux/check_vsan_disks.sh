#!/bin/sh

#DESCRIPTION
#   Check vSphere vSAN disks from ESXi

#NOTES
#   File Name  : check_vsan_disks.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   - Put this script on /var/prtg/scripsxml and use "SSH Advanced Script"
#	- Required parameters, last value indicate debug mode (1): esxi01.corp.local "naa.55cd2e414d79d151 naa.50000397980bfbcd naa.50000396381bc461 naa.50000397980bd569 naa.50000397985aed01 naa.55cd2e414d59cebb naa.50000396381b3c51 naa.5000c50088604113 naa.5000c500995ed2a7 naa.5000c50099496923" 0
#	- It's necessary add ssh credentials on device
#	- Set sensor timeout to 120 seconds 
#   - Command return follow results:
#[root@esxi241029:/var/prtg/scriptsxml] esxcli vsan debug disk overview
#UUID                                  Name                  Owner                    Ver  Disk Group                            Disk Tier    SSD  Metadata  Ops    Congestion  CMMDS   VSI  Capacity   Used       Reserved
#------------------------------------  --------------------  -----------------------  ---  ------------------------------------  ---------  -----  --------  -----  ----------  -----  ----  ---------  ---------  ---------
#5288e6ce-eb70-dca3-4374-f46a936c3ad9  naa.55cd2e414d79d151  esxi241112.domain.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Cache       true  green     green  No           true  true  N/A        N/A        N/A
#527e4b77-7bfb-7923-9437-bb02949975f2  naa.50000397980bfbcd  esxi241112.domain.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  536.15 GB  120.28 GB
#5229b48a-446b-8fa3-2c36-d56b32af14e9  naa.50000396381bc461  esxi241112.domain.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  530.98 GB  131.80 GB
#52dcea52-9943-5549-c29d-7e123c9abf2e  naa.50000397980bd569  esxi241112.domain.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  513.07 GB  98.77 GB
#52189a1f-4071-d500-3c49-bfdebb8fbea7  naa.50000397985aed01  esxi241112.domain.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  517.96 GB  114.60 GB
#520f2a07-ac73-abd1-7e7e-8ff5c35255e0  naa.55cd2e404c52bdbd  esxi241029.domain.local    5  520f2a07-ac73-abd1-7e7e-8ff5c35255e0  Cache       true  green     green  No           true  true  N/A        N/A        N/A
#52481020-1d86-1ad1-6a5b-694638316d9b  naa.50000397980bd635  esxi241029.domain.local    5  520f2a07-ac73-abd1-7e7e-8ff5c35255e0  Capacity   false  green     green  No           true  true  558.90 GB  536.56 GB  62.64 GB
#5223e6bc-b564-5686-b5eb-083280b189f1  naa.50000397980bf0c5  esxi241029.domain.local    5  520f2a07-ac73-abd1-7e7e-8ff5c35255e0  Capacity   false  green     green  No           true  true  558.90 GB  519.86 GB  86.33 GB
#52052767-e438-c14a-1ee2-8cad08dc1d69  naa.50000397980bc371  esxi241029.domain.local    5  520f2a07-ac73-abd1-7e7e-8ff5c35255e0  Capacity   false  green     green  No           true  true  558.90 GB  537.59 GB  104.88 GB
#52a02fd8-34e6-f334-b834-8fe8bbe95c7b  naa.50000397980bd4c1  esxi241029.domain.local    5  520f2a07-ac73-abd1-7e7e-8ff5c35255e0  Capacity   false  green     green  No           true  true  558.90 GB  533.88 GB  160.45 GB
#52041fb4-3bdd-ca2b-6d04-63dc2d1e62cd  naa.55cd2e414d79d164  esxi241045.domain.local    5  52041fb4-3bdd-ca2b-6d04-63dc2d1e62cd  Cache       true  green     green  No           true  true  N/A        N/A        N/A
#524ac0d0-3164-5740-e7eb-6dcf7b17b145  naa.5000c5009958d5f3  esxi241045.domain.local    5  52041fb4-3bdd-ca2b-6d04-63dc2d1e62cd  Capacity   false  green     green  No           true  true  558.90 GB  556.27 GB  73.72 GB
#529ea0d0-7d17-6db6-e27e-8e08bb91e0a4  naa.5000c5009958d447  esxi241045.domain.local    5  52041fb4-3bdd-ca2b-6d04-63dc2d1e62cd  Capacity   false  green     green  No           true  true  558.90 GB  539.06 GB  58.01 GB
#526d78ef-b997-8768-3a47-f8481f062529  naa.50000396381b3739  esxi241045.domain.local    5  52041fb4-3bdd-ca2b-6d04-63dc2d1e62cd  Capacity   false  green     green  No           true  true  558.90 GB  535.25 GB  57.66 GB
#520aac9a-ef52-7b3d-2bd1-af47e093f5c4  naa.50000396381bc21d  esxi241045.domain.local    5  52041fb4-3bdd-ca2b-6d04-63dc2d1e62cd  Capacity   false  green     green  No           true  true  558.90 GB  520.27 GB  78.05 GB
#5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  naa.55cd2e414d59cebb  esxi241112.domain.LOCAL    5  5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  Cache       true  green     green  No           true  true  N/A        N/A        N/A
#
#
#
#[root@esxi241029:/var/prtg/scriptsxml] esxcli vsan debug disk overview |awk '{print $2,$3,$4,$6,$9,$13,$15}'
#Name Owner Ver Group SSD CMMDS Capacity
#-------------------- ----------------------- --- --------- ----- --------- ---------
#naa.55cd2e404c52bdbd esxi241029.domain.local 5 Cache green N/A N/A
#naa.50000397980bd635 esxi241029.domain.local 5 Capacity green 558.90 534.56
#naa.50000397980bf0c5 esxi241029.domain.local 5 Capacity green 558.90 515.14
#naa.50000397980bc371 esxi241029.domain.local 5 Capacity green 558.90 544.52
#naa.50000397980bd4c1 esxi241029.domain.local 5 Capacity green 558.90 538.32
#naa.55cd2e414d79d151 esxi241112.domain.LOCAL 5 Cache green N/A N/A
#naa.50000397980bfbcd esxi241112.domain.LOCAL 5 Capacity green 558.90 535.81
#naa.50000396381bc461 esxi241112.domain.LOCAL 5 Capacity green 558.90 527.15
#naa.50000397980bd569 esxi241112.domain.LOCAL 5 Capacity green 558.90 514.29
#naa.50000397985aed01 esxi241112.domain.LOCAL 5 Capacity green 558.90 523.96
#naa.55cd2e414d79d164 esxi241045.domain.local 5 Cache green N/A N/A
#naa.5000c5009958d5f3 esxi241045.domain.local 5 Capacity green 558.90 556.27
#naa.5000c5009958d447 esxi241045.domain.local 5 Capacity green 558.90 529.93
#naa.50000396381b3739 esxi241045.domain.local 5 Capacity green 558.90 531.58
#naa.50000396381bc21d esxi241045.domain.local 5 Capacity green 558.90 514.21
#naa.55cd2e414d79d1a2 esxi241045.domain.local 5 Cache green N/A N/A
#naa.50000396381baa25 esxi241045.domain.local 5 Capacity green 558.90 515.45
#naa.50000396381acedd esxi241045.domain.local 5 Capacity green 558.90 524.92
#naa.5000039638200b6d esxi241045.domain.local 5 Capacity green 558.90 535.14
#naa.50000396381b8a35 esxi241045.domain.local 5 Capacity green 558.90 522.82
#naa.55cd2e414d59cebb esxi241112.domain.LOCAL 5 Cache green N/A N/A
#naa.50000396381b3c51 esxi241112.domain.LOCAL 5 Capacity green 558.90 525.23
#naa.5000c50088604113 esxi241112.domain.LOCAL 5 Capacity green 558.90 526.61
#naa.5000c500995ed2a7 esxi241112.domain.LOCAL 5 Capacity green 558.90 521.61
#naa.5000c50099496923 esxi241112.domain.LOCAL 5 Capacity green 558.90 522.80
#naa.55cd2e414d5845a0 esxi241029.domain.local 5 Cache green N/A N/A
#naa.5000c50088602ca3 esxi241029.domain.local 5 Capacity green 558.90 524.34
#naa.50000396381b325d esxi241029.domain.local 5 Capacity green 558.90 529.45
#naa.50000396381b2ee1 esxi241029.domain.local 5 Capacity green 558.90 528.50
#naa.5000c50088b99d07 esxi241029.domain.local 5 Capacity green 558.90 535.09
#
#
#
#
#
#CHANGELOG
#   v1 25/10/2019   Script creation
#	v2 31/10/2019	Add variables and adapt to PRTG xml result

esxi=$1
disks=$2
debug=$3

echo "<?xml version="1.0" encoding='UTF-8'?>
<prtg>"

for disk in $disks; do

result=$(esxcli vsan debug disk overview | grep $esxi |grep $disk |awk '{print $2,$3,$4,$5,$6,$9,$13,$15}')
#echo "$result"

#Disk name
disk_name=$(echo "$result" |awk '{print $1}')

#Disk owner
disk_owner=$(echo "$result" |awk '{print $2}')

#Disk version
disk_version=$(echo $result |awk '{print $3}')

#Disk group
disk_group=$(echo $result |awk '{print $4}')

#Disk tier
disk_tier=$(echo $result |awk '{print $5}')

#disk_status
disk_status=$(echo $result |awk '{print $6}')

#disk_capacity
disk_capacity=$(echo $result |awk '{print $7}')

#disk_used
disk_used=$(echo $result |awk '{print $8}')

if [ $debug == "1" ]; then
  echo Disk name: $disk_name
  echo Disk version: $disk_version
  echo Disk group: $disk_group
  echo Disk tier: $disk_tier
  echo Disk status: $disk_status
  echo Disk capacity: $disk_capacity
  echo Disk used: $disk_used
  echo Disk free: $disk_free
  echo Disk percent used: $disk_percent_used
fi

if [ $disk_status == "green" ]; then
  prtg_disk_status=0
else
  prtg_disk_status=5
fi

if [ $disk_tier == "Cache" ]; then
  echo "<result>
  <channel>STATUS: $disk_tier disk $disk_name</channel>
  <value>$prtg_disk_status</value>
  <LimitMode>1</LimitMode>
  <LimitMaxError>1</LimitMaxError>
  </result>"
else
  #disk_free > Discarding floating points
  disk_free=$(expr ${disk_capacity%\.*} - ${disk_used%\.*})
  #disk_percent > Calculate % usage
  disk_percent_used=$(expr ${disk_used%\.*} \* 100 / ${disk_capacity%\.*})
  echo "<result>
  <channel>STATUS: $disk_tier disk $disk_name</channel>
  <value>$prtg_disk_status</value>
  <LimitMode>1</LimitMode>
  <LimitMaxError>1</LimitMaxError>
  </result>
  <result>
  <channel>USAGE: $disk_tier disk $disk_name</channel>
  <unit>Percent</unit>
  <value>$disk_percent_used</value>
  <LimitMode>1</LimitMode>
  <LimitMaxWarning>90</LimitMaxWarning>
  <LimitMaxError>95</LimitMaxError>
  </result>"
fi

done

echo "<text>vSAN disk Heahth check | Host: $disk_owner </text>
</prtg>"

exit 0

