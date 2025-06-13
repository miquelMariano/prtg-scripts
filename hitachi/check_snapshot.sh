#!/bin/bash

LDEV=$1
instance=$2

# Tu texto
texto=$(raidcom get snapshot -ldev_id $LDEV -format_time -IH$instance |  tail -n 1 | grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')

# Extraer la fecha utilizando 'grep'
fecha=$(echo "$texto" | grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')

# Obtener la fecha actual en el mismo formato
fecha_actual=$(date +'%Y-%m-%dT%H:%M:%S')

# Convertir ambas fechas a formato de época (timestamp)
timestamp_fecha=$(date -d "$fecha" +%s)
timestamp_fecha_actual=$(date -d "$fecha_actual" +%s)

# Calcular la diferencia en segundos
diferencia_segundos=$((timestamp_fecha_actual - timestamp_fecha))

# Calcular la diferencia en horas
result=$((diferencia_segundos / 3600))

echo "0:$result:The last snapshot of the LDEV $LDEV was $result hours ago."

