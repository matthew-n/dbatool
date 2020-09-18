CREATE FUNCTION dbo.JobTextSearch(@SearchText AS varchar(1000))
RETURNS TABLE
AS 
RETURN(
	SELECT	j.job_id,
		s.srvname,
		j.name,
		js.step_id,
		js.command,
		j.enabled 
	FROM	msdb.dbo.sysjobs j
	JOIN	msdb.dbo.sysjobsteps js
		ON	js.job_id = j.job_id 
	JOIN	master.dbo.sysservers s
		ON	s.srvid = j.originating_server_id
	WHERE	CHARINDEX(@SearchText,js.command)>0
)
GO
