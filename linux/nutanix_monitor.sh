#!/bin/bash

#DESCRIPTION
#   Monitoriza ping y ssh desde PrismCentral a los nodos AHV y CVMs

#NOTES 
#   File Name  : nutanix_monitor.sh
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1

#USAGE
#   Dejar el script en /var/prtg/scriptsxml del Prism Central y usar "SSH script advanced sensor XML"
#   Para entornos grandes, fijar el "Shell Timeout (Sec.)" del sensor a un valor alto (ej. 60 segundos)  
#
#CHANGELOG
#   v1 04/11/2025   Creación del script
#  

# --- Configuración del Pool de IPs de las CVM y nodos AHV ---
IPS=(
    "10.100.250.139"  
    "10.100.250.140"  
    "10.100.250.141"  
    "10.100.250.142"
    "10.100.250.143"  
    "10.100.250.144"
    "10.100.250.145" 
    "10.100.250.149"  
    "10.100.250.150"  
    "10.100.250.151"  
    "10.100.250.152"
    "10.100.250.153"  
    "10.100.250.154"
    "10.100.250.155" 
)

SSH_PORT="22"       
PING_COUNT="1"      
TIMEOUT="3"         

echo "<prtg>"

for IP in "${IPS[@]}"; do

    ping -c $PING_COUNT -W $TIMEOUT $IP > /dev/null 2>&1
    PING_EXIT_CODE=$?

    if [ $PING_EXIT_CODE -eq 0 ]; then
        PING_VALUE="100"  # 100: UP
    else
        PING_VALUE="0"  # 0: DOWN
        PING_MESSAGE="Error - Host NO responde a PING."
    fi

    echo "  <result>"
    echo "    <channel>Ping - $IP</channel>"
    echo "    <value>$PING_VALUE</value>"
    echo "    <unit>Count</unit>"
    echo "    <LimitMode>1</LimitMode>"
    echo "    <LimitMinerror>1</LimitMinerror>"
    echo "    <LimitErrorMsg>$PING_MESSAGE</LimitErrorMsg>"
    echo "  </result>"

    nc -z -w $TIMEOUT $IP $SSH_PORT > /dev/null 2>&1
    SSH_EXIT_CODE=$?

    if [ $SSH_EXIT_CODE -eq 0 ]; then
        SSH_VALUE="100"   # 100: UP
    else
        SSH_VALUE="0"   # 0: DOWN
        SSH_MESSAGE="Error - Puerto SSH ($SSH_PORT) cerrado o inaccesible."
    fi

    echo "  <result>"
    echo "    <channel>SSH - $IP</channel>"
    echo "    <value>$SSH_VALUE</value>"
    echo "    <unit>Count</unit>"
    echo "    <LimitMode>1</LimitMode>"
    echo "    <LimitMinerror>1</LimitMinerror>"
    echo "    <LimitErrorMsg>$SSH_MESSAGE</LimitErrorMsg>"
    echo "  </result>"

done

echo "</prtg>" 