---DESCRIPTION
---   Check Oracle Response Time

---NOTES 
---   File Name  : oracle_response_time.sql
---   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
---   Version    : 1
---   Code       : https://github.com/miquelMariano/prtg-scripts/oracle

---USAGE
---   Put this script on C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\sql\oracle and use "Oracle SQL v2"
---
---CHANGELOG
---   v1 26/01/2021   Script creation
---   


select  CASE METRIC_NAME
            WHEN 'Response Time Per Txn' then 'Response Time Per Txn (secs)'
            ELSE METRIC_NAME
            END METRIC_NAME,
                CASE METRIC_NAME
            WHEN 'Response Time Per Txn' then ROUND((MINVAL / 100),2)
            ELSE MINVAL
            END MININUM,
                CASE METRIC_NAME
            WHEN 'Response Time Per Txn' then ROUND((MAXVAL / 100),2)
            ELSE MAXVAL
            END MAXIMUM,
                CASE METRIC_NAME
            WHEN 'Response Time Per Txn' then ROUND((AVERAGE / 100),2)
            ELSE AVERAGE
            END AVERAGE
from    SYS.V_$SYSMETRIC_SUMMARY
where   METRIC_NAME in ('Response Time Per Txn')
ORDER BY 1;