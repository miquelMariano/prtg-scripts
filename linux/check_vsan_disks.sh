#!/bin/sh

#DESCRIPTION
#   Check vSphere vSAN disks from ESXi

#NOTES
#   File Name  : check_vsan_disks.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   Put this script on /var/prtg/scripsxml and use "SSH Advanced Script"
#	It's necessary add ssh credentials on device
#   Command return follow results:
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
#[root@indme241029:/var/prtg/scriptsxml] esxcli vsan debug disk overview | grep indme241112.INDAR.LOCAL
#5288e6ce-eb70-dca3-4374-f46a936c3ad9  naa.55cd2e414d79d151  indme241112.INDAR.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Cache       true  green     green  No           true  true  N/A        N/A        N/A
#527e4b77-7bfb-7923-9437-bb02949975f2  naa.50000397980bfbcd  indme241112.INDAR.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  536.15 GB  120.28 GB
#35229b48a-446b-8fa3-2c36-d56b32af14e9  naa.50000396381bc461  indme241112.INDAR.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  530.98 GB  131.80 GB
#52dcea52-9943-5549-c29d-7e123c9abf2e  naa.50000397980bd569  indme241112.INDAR.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  513.07 GB  98.77 GB
#52189a1f-4071-d500-3c49-bfdebb8fbea7  naa.50000397985aed01  indme241112.INDAR.LOCAL    5  5288e6ce-eb70-dca3-4374-f46a936c3ad9  Capacity   false  green     green  No           true  true  558.90 GB  517.96 GB  114.60 GB
#5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  naa.55cd2e414d59cebb  indme241112.INDAR.LOCAL    5  5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  Cache       true  green     green  No           true  true  N/A        N/A        N/A
#52233743-4253-9131-80f3-7983f5e50a4f  naa.50000396381b3c51  indme241112.INDAR.LOCAL    5  5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  Capacity   false  green     green  No           true  true  558.90 GB  547.86 GB  151.16 GB
#52d2b3ab-38b6-3531-5450-6b75c883d617  naa.5000c50088604113  indme241112.INDAR.LOCAL    5  5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  Capacity   false  green     green  No           true  true  558.90 GB  519.67 GB  102.77 GB
#5254fa18-2056-8a8e-fdb7-98d686f97b99  naa.5000c500995ed2a7  indme241112.INDAR.LOCAL    5  5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  Capacity   false  green     green  No           true  true  558.90 GB  529.07 GB  122.78 GB
#52d55fe7-fa6b-d31f-009e-4f0f641b0f0c  naa.5000c50099496923  indme241112.INDAR.LOCAL    5  5287635d-ce4a-d68f-5e1d-dc0cc8a21abb  Capacity   false  green     green  No           true  true  558.90 GB  526.73 GB  126.74 GB
#
#
#
#CHANGELOG
#   v1 25/10/2019   Script creation
#

esxi=$1

result=$(esxcli vsan debug disk overview | grep $esxi)

echo "$result" | awk 'FNR == 2 {print $3}'


xmlresult=`cat <<EOF
<?xml version="1.0" encoding='UTF-8'?>
            <prtg>
            <result>
            <channel>First channel</channel>
            <value>10</value>
            </result>
            <result>
            <channel>Second channel</channel>
            <value>20</value>
            </result>
            </prtg>
EOF
`
echo "$xmlresult"

exit 0

