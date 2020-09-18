CREATE FUNCTION [metadata].[ChangeLog] ( @obj_id as INT )
RETURNS TABLE
AS 
RETURN (
	SELECT 
		rev.value('@version','float') AS VersionNumber,
		rev.value('@date','[date]') AS PulicationDate,
		rev.value('@author', 'nvarchar(4)') AS AuthorInitials,	
		change.value('(./text())[1]','nvarchar(4000)') AS ChangeStatement
	FROM metadata.Properties AS P
	CROSS APPLY (SELECT convert(XML,CONVERT(NVARCHAR(4000),propertyValue),3) ) AS calc(DATA)
	CROSS APPLY data.nodes('/revisionhist/revision') tbl1(rev)
	CROSS APPLY rev.nodes('change') tbl2(change)
	WHERE
		p.ObjectName = OBJECT_NAME(@obj_id)
		AND p.SchemaName = OBJECT_SCHEMA_NAME(@obj_id)
		AND P.PropertyName = 'changelog'
	)
GO
