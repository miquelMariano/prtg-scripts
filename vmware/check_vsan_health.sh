#!/bin/sh

#DESCRIPTION
#   Check vSphere vSAN health from ESXi

#NOTES
#   File Name  : check_vsan_health.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   Put this script on /var/prtg/scrips and use "SSH Script"
#	It's necessary add ssh credentials on device
#   Command return follow results:
#     [root@esxi:/var/prtg/scripts] esxcli vsan debug object health summary get
#     Health Status                                     Number Of Objects
#     ------------------------------------------------  -----------------
#     reduced-availability-with-no-rebuild-delay-timer                  0
#     healthy                                                        1030
#     reduced-availability-with-no-rebuild                              0
#     data-move                                                         0
#     nonavailability-related-incompliance                              0
#     nonavailability-related-reconfig                                  0
#     inaccessible                                                      0
#     reduced-availability-with-active-rebuild                          0
#
#
#CHANGELOG
#   v1 29/08/2019   Script creation
#

value=$1

result=$(esxcli vsan debug object health summary get | grep $value | awk '{print $2}')

echo "0:$result:Objects $value = $result"
