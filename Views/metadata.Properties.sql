


CREATE VIEW [metadata].[Properties]
	( FullName
	,PropertyName
	,PropertyValue
	,ObjectType
	,SchemaName
	,ObjectName
	,SubName )
AS
SELECT
	calc.FullName,
	xp.name AS PropertyName,
	xp.value AS PropertyValue,
	CASE 
		WHEN o.object_id IS NOT NULL THEN o.type_desc
		WHEN col.column_id IS NOT NULL THEN 'COLUMN'
		ELSE
			COALESCE(xp.class_desc,'Undefined') 
	END AS ObjectType,
	OBJECT_SCHEMA_NAME(xp.major_id) AS SchemaName,
	OBJECT_NAME(xp.major_id) AS ObjectName,
	COALESCE(col.name,p.name) SubName
FROM sys.extended_properties AS xp
LEFT JOIN sys.objects AS O 
	ON xp.major_id = O.object_id 
	AND xp.minor_id = 0 
	AND xp.class_desc = 'OBJECT_OR_COLUMN'
LEFT JOIN sys.columns AS col 
	ON xp.major_id = col.object_id 
	AND xp.minor_id = col.column_id 
	AND xp.class_desc = 'OBJECT_OR_COLUMN'
LEFT JOIN sys.parameters AS P 
	ON xp.major_id = p.object_id 
	AND xp.minor_id = p.parameter_id 
	AND xp.class_desc = 'PARAMETER'
LEFT JOIN sys.indexes AS idx
	ON xp.major_id = idx.object_id
	AND xp.minor_id = idx.index_id
	AND xp.class_desc ='INDEX'
CROSS APPLY(
	SELECT
		QUOTENAME(COALESCE(OBJECT_SCHEMA_NAME(xp.major_id),o.name,DB_NAME()))
			+ISNULL('.' + QUOTENAME(OBJECT_NAME(xp.major_id)),'')
			+ISNULL('.'+ QUOTENAME(COALESCE(col.name,p.name)),'')
		AS FullName

) AS calc
GO
-- =============================================
-- Author:		Matthew Naul
-- Create date: 2012-10-14
-- Description: Trigger to allow easy metat data update
-- =============================================
CREATE TRIGGER [metadata].[ExtentedPropCRUD] ON [metadata].[Properties]
	INSTEAD OF INSERT, DELETE, UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @action AS VARCHAR(10)
	       ,@name AS SYSNAME
	       ,@value AS SQL_VARIANT
	       ,@level0type AS VARCHAR(128)
	       ,@level0name AS SYSNAME
	       ,@level1type AS VARCHAR(128)
	       ,@level1name AS SYSNAME
	       ,@level2type AS VARCHAR(128)
	       ,@level2name AS SYSNAME;
	
-- build a change table instead of a merge statment (see below)
	SELECT
		CASE WHEN i.FullName IS NULL THEN 'Delete'
			 WHEN d.FullName IS NULL THEN 'Add'
			 ELSE 'Update'
		END AS [Action]
	   ,COALESCE(i.FullName, d.FullName) AS FullName
	   ,COALESCE(i.PropertyName, d.PropertyName) AS PropertyName
	   ,COALESCE(i.PropertyValue, d.PropertyValue) AS PropertyValue
	INTO
		#List
	FROM
		INSERTED AS i
	FULL JOIN DELETED AS d
	ON	i.FullName = d.FullName

--we have no choise but to use currosrs here 
--SQL Sever only has store pocedures to update this data
	DECLARE curChangeSet CURSOR FAST_FORWARD READ_ONLY
	FOR
	SELECT
		[Action]
	   ,PropertyName
	   ,PropertyValue
	   ,oi.level0type
	   ,oi.level0name
	   ,oi.level1type
	   ,oi.level1name
	   ,oi.level2type
	   ,oi.level2name
	FROM #List AS t 
	-- used to prevent insert of metadata for objects that don't exist
	CROSS APPLY metadata.ObjectInfo(t.FullName) AS oi

	OPEN curChangeSet

	FETCH NEXT FROM curChangeSet 
	INTO 
		@action, @name, @value,
		@level0type, @level0name,
		@level1type, @level1name,
		@level2type, @level2name

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @action = 'Add'
			EXEC sys.sp_addextendedproperty  @name, @value,
				@level0type, @level0name,
				@level1type, @level1name,
				@level2type, @level2name
		ELSE
			IF @action = 'Update'
				EXEC sys.sp_updateextendedproperty  @name, @value,
					@level0type, @level0name,
					@level1type, @level1name,
					@level2type, @level2name
			ELSE
				IF @action = 'Delete'
					EXEC sys.sp_dropextendedproperty  @name,
						@level0type, @level0name,
						@level1type, @level1name,
						@level2type, @level2name

		FETCH NEXT FROM curChangeSet 
		INTO 
			@action, @name, @value,
			@level0type, @level0name,
			@level1type, @level1name,
			@level2type, @level2name
	END

	CLOSE curChangeSet
	DEALLOCATE curChangeSet

	DROP TABLE #list
END

GO
EXEC sp_addextendedproperty N'MS_Description', N'A View to make extened properties easier to deal with', 'SCHEMA', N'metadata', 'VIEW', N'Properties', NULL, NULL
GO
EXEC sp_addextendedproperty N'SUBSYSTEM', N'META', 'SCHEMA', N'metadata', 'VIEW', N'Properties', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Relative to the database the fully qualified name of the object or sub-object.', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'FullName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This will typicaly be a table name but could be other types of objects. (ex. View Name, function name, etc.)', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'ObjectName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The full object type description from the system tables.', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'ObjectType'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The extened property name, extened properties are simple name value pairs.', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'PropertyName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Values of the extened property. Datatype SQL variant.', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'PropertyValue'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The Permissions schema containing the object or the name of a permissions schema itself.', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'SchemaName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'This will contain the column''s name, in common cases, with applicable. Tables are consideres objecs indexes and columns are sub-objects.', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'COLUMN', N'SubName'
GO
EXEC sp_addextendedproperty N'MS_Description', N'1.Creates a changes temp table
2.iterates over it with a cursor
3.Adds, Updates, Deletes extended properties as needed.
', 'SCHEMA', N'metadata', 'VIEW', N'Properties', 'TRIGGER', N'ExtentedPropCRUD'
GO
