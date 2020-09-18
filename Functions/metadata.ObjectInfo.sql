
CREATE FUNCTION [metadata].[ObjectInfo] ( @obj VARCHAR(MAX) )
RETURNS TABLE
	AS RETURN
	(
	SELECT
		ObjectSchema = s.name
	   ,ObjectName = NULL
	   ,FullObjectName = QUOTENAME(s.name)
	   ,ObjectType = 'SCHEMA'
	   ,IsSchema = CAST(1 AS BIT)
	   ,level0type = 'SCHEMA'
	   ,level0name = s.name
	   ,level1type = NULL
	   ,level1name = NULL
	   ,level2type = NULL
	   ,level2name = NULL
	FROM sys.schemas AS S
	WHERE
		s.schema_id = SCHEMA_ID(@obj)
	UNION ALL
	SELECT
	 OBJECT_SCHEMA_NAME(o.object_id) AS ObjectSchema
	,o.name
	,calc.FullObjectName
	,o.type_desc AS ObjectType
	,CAST(0 AS BIT) AS IsSchema
	,'SCHEMA' AS level0type 
	,OBJECT_SCHEMA_NAME(o.object_id) AS level0name 
	,calc.level1type
	,o.name AS level1name
	,NULL AS level2type
	,NULL AS level2name
	FROM sys.objects AS o
	CROSS APPLY (
		SELECT
			QUOTENAME(OBJECT_SCHEMA_NAME(o.object_id)) + '.' 
				+ QUOTENAME(o.name)
			AS FullObjectName,
			CASE type_desc
						WHEN 'VIEW' THEN 'VIEW'
						WHEN 'USER_TABLE' THEN 'TABLE'
						WHEN 'SQL_STORED_PROCEDURE' THEN 'PROCEDURE'
						WHEN 'SQL_SCALAR_FUNCTION' THEN 'FUNCTION'
						WHEN 'CLR_SCALAR_FUNCTION' THEN 'FUNCTION'
						WHEN 'SQL_TABLE_VALUED_FUNCTION' THEN 'FUNCTION'
						WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 'FUNCTION'
						ELSE o.type_desc
			END
	) AS calc(FullObjectName,level1type)
	WHERE
		o.object_id = OBJECT_ID(@obj)
	UNION ALL
	SELECT
		 OBJECT_SCHEMA_NAME(o.object_id) AS ObjectSchema
		,OBJECT_NAME(o.object_id) AS ObjectName
		,calc.FullObjectName
		,o.type_desc AS ObjectType
		,CAST(0 AS BIT) AS IsSchema
		,'SCHEMA' AS level0type
		,OBJECT_SCHEMA_NAME(o.object_id) AS level0name
		,calc.level1type 
		,level1name = OBJECT_NAME(o.object_id)
		,SubObj.level2type
		,SubObj.level2name
	FROM sys.objects AS O
	JOIN (
		SELECT
			c.object_id AS parent_id,
			'COLUMN' AS level2type,
			c.NAME AS level2name
		FROM sys.columns AS C 
		UNION ALL
		SELECT
			I.object_id AS parent_id,
			'INDEX' AS level2type,
			I.NAME AS level2name
		FROM sys.indexes AS I
		UNION ALL
		SELECT
			p.object_id AS parent_id,
			'PARAMATER' AS level2type,
			p.NAME AS level2name
		FROM sys.parameters AS P
	) AS SubObj ON o.object_id = SubObj.parent_id
	CROSS APPLY (
		SELECT
			QUOTENAME(OBJECT_SCHEMA_NAME(o.object_id)) + '.' 
				+ QUOTENAME(o.name)+'.'
				+QUOTENAME(SubObj.level2name)
			AS FullObjectName,
			CASE type_desc
						WHEN 'VIEW' THEN 'VIEW'
						WHEN 'USER_TABLE' THEN 'TABLE'
						WHEN 'SQL_STORED_PROCEDURE' THEN 'PROCEDURE'
						WHEN 'SQL_SCALAR_FUNCTION' THEN 'FUNCTION'
						WHEN 'CLR_SCALAR_FUNCTION' THEN 'FUNCTION'
						WHEN 'SQL_TABLE_VALUED_FUNCTION' THEN 'FUNCTION'
						WHEN 'SQL_INLINE_TABLE_VALUED_FUNCTION' THEN 'FUNCTION'
						ELSE o.type_desc
			END
	) AS calc(FullObjectName,level1type)
	WHERE
		PARSENAME(@obj, 1) IS NOT NULL AND
		PARSENAME(@obj, 2) IS NOT NULL AND
		PARSENAME(@obj, 3) IS NOT NULL AND
		PARSENAME(@obj, 4) IS NULL AND
		o.object_id = OBJECT_ID(QUOTENAME(PARSENAME(@obj, 3)) + '.' + QUOTENAME(PARSENAME(@obj, 2))) AND
		SubObj.level2name = PARSENAME(@obj, 1)
	)
GO
EXEC sp_addextendedproperty N'MS_Description', N'Return XP-friendly object types. Internal to the Properties view.', 'SCHEMA', N'metadata', 'FUNCTION', N'ObjectInfo', NULL, NULL
GO
EXEC sp_addextendedproperty N'SUBSYSTEM', N'META', 'SCHEMA', N'metadata', 'FUNCTION', N'ObjectInfo', NULL, NULL
GO
