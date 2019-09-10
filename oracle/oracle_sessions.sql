---DESCRIPTION
---   Check Oracle Status

---NOTES 
---   File Name  : oracle_sessions.sql
---   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
---   Version    : 1
---   Code       : https://github.com/miquelMariano/prtg-scripts/oracle

---USAGE
---   Put this script on C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\sql\oracle and use "Oracle SQL v2"
---
---CHANGELOG
---   v1 10/09/2019   Script creation
---   

select 
	resource_name, current_utilization
from 
	v$resource_limit 
where 
	resource_name in ('processes','sessions');