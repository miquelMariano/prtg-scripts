---DESCRIPTION
---   Check Oracle Status

---NOTES 
---   File Name  : oracle_tablespace.sql
---   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
---   Version    : 1
---   Code       : https://github.com/miquelMariano/prtg-scripts/oracle

---USAGE
---   Put this script on C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\sql\oracle and use "Oracle SQL v2"
---
---CHANGELOG
---   v1 10/09/2019   Script creation
---   


SELECT 
    tablespace_name,ROUND(sum(bytes)/1024/1024,0)
FROM 
    dba_free_space 
WHERE 
    tablespace_name in ('PSAPSR3','PSAPSR3740') 
GROUP BY 
    tablespace_name;