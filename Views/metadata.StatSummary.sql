

CREATE VIEW [metadata].[StatSummary] AS
SELECT a.schemaName,
       a.tableName,
       a.statsName,
       a.object_id,
       a.stats_id,
       a.statsUpdate,
       a.statsType,
       a.indexName,
       a.index_id,
       a.modCounter,
        rowCounts.row_count 
FROM (
        SELECT  sc.name schemaName,
                o.name tableName,
                s.name statsName,
                s.object_id,
                s.stats_id,
                STATS_DATE(o.object_id, s.stats_id) statsupdate,
                CASE WHEN i.index_id IS NULL THEN 'COLUMN' ELSE 'INDEX' END AS statstype,
                ISNULL( i.name, ui.name ) AS indexName,
                ISNULL( i.index_id, ui.index_id ) AS index_id,
                sp.modification_counter AS modCounter
        FROM sys.stats s
            INNER JOIN sys.objects o ON s.object_id = o.object_id
            INNER JOIN sys.schemas sc ON o.schema_id = sc.schema_id

            -- If a statistics object is on an index, get that index:
            LEFT JOIN sys.indexes i ON s.object_id = i.object_id AND s.stats_id = i.index_id

            -- If the statistics objects is not on an index, get the underlying table:
            LEFT JOIN sys.indexes ui ON s.object_id = ui.object_id AND ui.index_id IN ( 0, 1 )
            OUTER APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
		WHERE
			o.is_ms_shipped = 0
    ) AS a
    INNER JOIN (
        SELECT object_id, index_id, SUM(row_count) row_count
        FROM sys.dm_db_partition_stats
        GROUP BY object_id, index_id
        HAVING SUM( row_count ) > 0
    ) AS rowCounts ON a.object_id = rowCounts.object_id 
        AND a.index_id = rowCounts.index_id
GO
EXEC sp_addextendedproperty N'author', N'Merrill Aldrich', 'SCHEMA', N'metadata', 'VIEW', N'StatSummary', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'View for tabluarly showing stats', 'SCHEMA', N'metadata', 'VIEW', N'StatSummary', NULL, NULL
GO
EXEC sp_addextendedproperty N'source', N'http://sqlblog.com/blogs/merrill_aldrich/archive/2013/09/18/stats-on-stats.aspx', 'SCHEMA', N'metadata', 'VIEW', N'StatSummary', NULL, NULL
GO
