CREATE VIEW ToolSettings.BlitzChecksToSkip
AS
SELECT DISTINCT 
	BCTS.ServerName
	,BCTS.DatabaseName
	,F.CheckID
FROM OzarTools.BlitzChecksToSkip AS BCTS
JOIN OzarTools.Finding AS F ON BCTS.FindingID = F.ID
GO
