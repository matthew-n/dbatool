
CREATE VIEW [ServerSettings].[Configure]
AS
SELECT
	c.configuration_id
   ,c.name
   ,c.description
   ,c.value
   ,c.value_in_use
   ,d.default_value
   ,c.minimum
   ,c.maximum  
   ,IIF(c.value = d.default_value,1,0) AS is_default
   ,delta.reason AS changeReason
   ,c.is_dynamic
   ,c.is_advanced
   ,IIF(c.value = c.value_in_use,1,0) AS is_applied
FROM sys.configurations c
LEFT JOIN ServerSettings.ConfigDefaults AS d ON	c.name = d.property
LEFT JOIN ServerSettings.ConfigChangeReason AS delta ON c.name = delta.property AND delta.expiredDate IS NULL

GO
-- =============================================
-- Author:		Matthew Naul
-- Create date: Nov. 20, 2013
-- Description:	Update the server configurations and log
-- =============================================
CREATE TRIGGER [ServerSettings].[SettingsUpdate] 
   ON  [ServerSettings].[Configure] 
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY
	
		DECLARE @hold AS TABLE(action_out NVARCHAR(50), name NVARCHAR(35), value SQL_VARIANT, changeReason VARCHAR(8000) );
	
		IF EXISTS (SELECT 1 FROM INSERTED WHERE changeReason IS NULL)
			RAISERROR ('Need to complete the reason field before updating settings!', 16, 1);

	-- build a change table instead of a merge statment (see below)	

		MERGE INTO ServerSettings.ConfigChangeReason AS dest
		USING INSERTED AS src ON dest.property = src.NAME AND dest.expiredDate IS NULL
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (property, new_value, Reason)
			VALUES(src.name, src.value, src.changeReason)
		WHEN MATCHED THEN
			UPDATE set expiredDate = GETDATE()
		OUTPUT $ACTION action_out, src.name, src.value, src.changeReason
		INTO @hold;

		INSERT INTO ServerSettings.ConfigChangeReason(property, new_value, Reason)
		SELECT
			 H.name
			,H.value
			,H.changeReason
		FROM @hold AS H
		WHERE H.action_out = 'UPDATE';
	
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO
EXEC sp_addextendedproperty N'MS_Description', N'most current reason from ConfigChangeReason', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'changeReason'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The configuration id from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'configuration_id'
GO
EXEC sp_addextendedproperty N'MS_Description', N'default value save in local table ConfigurationDefaults, not version specific yet', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'default_value'
GO
EXEC sp_addextendedproperty N'MS_Description', N'from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'description'
GO
EXEC sp_addextendedproperty N'MS_Description', N'from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'is_advanced'
GO
EXEC sp_addextendedproperty N'MS_Description', N'convient bit filter between value and value_in_use', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'is_applied'
GO
EXEC sp_addextendedproperty N'MS_Description', N'from ConfigurationDefaults if avalible', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'is_default'
GO
EXEC sp_addextendedproperty N'MS_Description', N'from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'is_dynamic'
GO
EXEC sp_addextendedproperty N'MS_Description', N'from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'maximum'
GO
EXEC sp_addextendedproperty N'MS_Description', N'from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'minimum'
GO
EXEC sp_addextendedproperty N'MS_Description', N'name of the configuration being update (eg the string the sp_configure statment)', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'name'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Configured value from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'value'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Value being used by the engine from sys.configurations', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'COLUMN', N'value_in_use'
GO
EXEC sp_addextendedproperty N'MS_Description', N'makes quick work of documenting your most recent change to the server configurations.', 'SCHEMA', N'ServerSettings', 'VIEW', N'Configure', 'TRIGGER', N'SettingsUpdate'
GO
