#!/bin/bash

#DESCRIPTION
#   Check memory on linux systems

#NOTES 
#   File Name  : meminfo.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   Put this script on /var/prtg/scriptsxml and use "SSH script advanced sensor XML"
#   
#CHANGELOG
#   v1 26/08/2019   Script creation
#   



meminfo="/usr/bin/free"

xmlresult=`cat <<EOF
<?xml version="1.0" encoding='UTF-8'?>
<prtg>
EOF
`

if [ -f $meminfo ]; then
  result=`free -b | grep 'Mem\|Swap'`
  while read line; do
    if [[ $line == Mem* ]]; then
      total=`echo $line | awk '{print $2}'`
      used=`echo $line | awk '{print $3}'`
      free=`echo $line | awk '{print $4}'`
      shared=`echo $line | awk '{print $5}'`
      buffers=`echo $line | awk '{print $6}'`
      available=`echo $line | awk '{print $7}'`
    else
      swtotal=`echo $line | awk '{print $2}'`
      swused=`echo $line | awk '{print $3}'`
      swfree=`echo $line | awk '{print $4}'`
    fi
  done <<< "$result"

  availableperc=`echo $available $total | \
    awk '{printf("%.3f",($1/$2)*100)}'`
  xmlresult+=`cat << EOF

  <result>
    <channel>Available Percent</channel>
    <float>1</float>
    <unit>Percent</unit>
    <value>$availableperc</value>
    <LimitMode>1</LimitMode>
    <LimitMinWarning>10</LimitMinWarning>
    <LimitMinError>5</LimitMinError>
  </result>
EOF
`
  availablebytes=$available
  xmlresult+=`cat << EOF

  <result>
    <channel>Available Bytes</channel>
    <float>0</float>
    <unit>BytesMemory</unit>
    <value>$availablebytes</value>
  </result>
EOF
`
physicalusedperc=`echo $free $total | \
    awk '{printf("%.3f", (100-(($1/$2)*100)))}'`
  xmlresult+=`cat <<EOF

  <result>
    <channel>Physical Used Percent</channel>
    <float>1</float>
    <unit>Percent</unit>
    <value>$physicalusedperc</value>
  </result>
EOF
`
  physicalfreebytes=$free
  xmlresult+=`cat <<EOF

  <result>
    <channel>Physical Free</channel>
    <float>0</float>
    <unit>BytesMemory</unit>
    <value>$physicalfreebytes</value>
  </result>
EOF
`
  swapusedperc=`echo $swtotal $swused | \
    awk '{printf("%.3f", ($2/$1)*100)}'`
  xmlresult+=`cat <<EOF

  <result>
    <channel>Swap Used Percent</channel>
    <float>1</float>
    <unit>Percent</unit>
    <value>$swapusedperc</value>
    <limitMode>1</limitMode>
  </result>
EOF
`
  xmlresult+=`cat <<EOF

  <result>
    <channel>Swap Used</channel>
    <float>0</float>
    <unit>BytesMemory</unit>
    <value>$swused</value>
  </result>
EOF
`
  xmlresult+=`cat <<EOF

  <result>
    <channel>Swap Free</channel>
    <float>0</float>
    <unit>BytesMemory</unit>
    <value>$swfree</value>
  </result>
EOF
`

  xmlresult+=`cat <<EOF

  <text>OK</text>
</prtg>
EOF
`

else
  xmlresult+=`cat <<EOF

  <error>1</error>
  <text>This sensor is not supported by your system, missing $proc</text>
</prtg>
EOF
`
fi

echo "$xmlresult"

exit 0
