

#DESCRIPTION
#   Check Oracle Status
#   https://github.com/miquelMariano/prtg-scripts

#NOTES 
#   File Name  : oracle_status.sql
#   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
#   Version    : 1
#   Code       : https://github.com/miquelMariano/prtg-scripts/oracle

#USAGE
#   Put this script on C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\sql\oracle and use "Oracle SQL v2"
#   See: https://kb.paessler.com/en/topic/63259-how-can-i-monitor-strings-from-an-sql-database-and-show-a-sensor-status-depending-on-it  
#
#CHANGELOG
#   v1 10/09/2019   Script creation
#   

# Original query: select status from v$instance;

select  
  CASE
    WHEN status = 'OPEN' THEN 0
    ELSE 100
  END as status  
from 
   v$instance;