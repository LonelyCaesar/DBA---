--Homework
--Chapter2
select '--Chapter2--';

USE master;
GO
SELECT name, value 
FROM sys.configurations
WHERE name in
('max server memory (MB)', 'max degree of parallelism', 
'cost threshold for parallelism');

--Chapter3
select '--Chapter3--';

SELECT name, physical_name AS CurrentLocation
FROM sys.master_files
WHERE DB_NAME(database_id) NOT in ('master', 'msdb', 'model')
order by DB_NAME(database_id);

--Chapter4
select '--Chapter4--';

DECLARE @dbname sysname, @days int
SET @dbname = NULL --substitute for whatever database name you want
SET @days = -30 --previous number of days, script will default to 30
SELECT
rsh.destination_database_name AS [Database],
rsh.user_name AS [Restored By],
CASE WHEN rsh.restore_type = 'D' THEN 'Database'
  WHEN rsh.restore_type = 'F' THEN 'File'
  WHEN rsh.restore_type = 'G' THEN 'Filegroup'
  WHEN rsh.restore_type = 'I' THEN 'Differential'
  WHEN rsh.restore_type = 'L' THEN 'Log'
  WHEN rsh.restore_type = 'V' THEN 'Verifyonly'
  WHEN rsh.restore_type = 'R' THEN 'Revert'
  ELSE rsh.restore_type
 END AS [Restore Type],
rsh.restore_date AS [Restore Started],
bmf.physical_device_name AS [Restored From],
 rf.destination_phys_name AS [Restored To]
FROM msdb.dbo.restorehistory rsh
INNER JOIN msdb.dbo.backupset bs ON rsh.backup_set_id = bs.backup_set_id
INNER JOIN msdb.dbo.restorefile rf ON rsh.restore_history_id = rf.restore_history_id
INNER JOIN msdb.dbo.backupmediafamily bmf ON bmf.media_set_id = bs.media_set_id
WHERE rsh.restore_date >= DATEADD(dd, ISNULL(@days, -30), GETDATE()) --want to search for previous days
AND destination_database_name = ISNULL(@dbname, destination_database_name) --if no dbname, then return all
ORDER BY rsh.restore_history_id DESC
GO

--Chapter5
select '--Chapter5--';

SELECT 
    [sJOB].[job_id] AS [JobID]
    , [sJOB].[name] AS [JobName]
    , [sDBP].[name] AS [JobOwner]
    , [sCAT].[name] AS [JobCategory]
    , [sJOB].[description] AS [JobDescription]
    , CASE [sJOB].[enabled]
        WHEN 1 THEN 'Yes'
        WHEN 0 THEN 'No'
      END AS [IsEnabled]
    , [sJOB].[date_created] AS [JobCreatedOn]
    , [sJOB].[date_modified] AS [JobLastModifiedOn]
    , [sSVR].[name] AS [OriginatingServerName]
    , [sJSTP].[step_id] AS [JobStartStepNo]
    , [sJSTP].[step_name] AS [JobStartStepName]
    , CASE
        WHEN [sSCH].[schedule_uid] IS NULL THEN 'No'
        ELSE 'Yes'
      END AS [IsScheduled]
    , [sSCH].[schedule_uid] AS [JobScheduleID]
    , [sSCH].[name] AS [JobScheduleName]
    , CASE [sJOB].[delete_level]
        WHEN 0 THEN 'Never'
        WHEN 1 THEN 'On Success'
        WHEN 2 THEN 'On Failure'
        WHEN 3 THEN 'On Completion'
      END AS [JobDeletionCriterion]
FROM
    [msdb].[dbo].[sysjobs] AS [sJOB]
    LEFT JOIN [msdb].[sys].[servers] AS [sSVR]
        ON [sJOB].[originating_server_id] = [sSVR].[server_id]
    LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT]
        ON [sJOB].[category_id] = [sCAT].[category_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP]
        ON [sJOB].[job_id] = [sJSTP].[job_id]
        AND [sJOB].[start_step_id] = [sJSTP].[step_id]
    LEFT JOIN [msdb].[sys].[database_principals] AS [sDBP]
        ON [sJOB].[owner_sid] = [sDBP].[sid]
    LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH]
        ON [sJOB].[job_id] = [sJOBSCH].[job_id]
    LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH]
        ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
ORDER BY [JobName]


--Chapter6
select '--Chapter6--';

DECLARE @dbname VARCHAR(50)   
DECLARE @statement NVARCHAR(MAX)

DECLARE db_cursor CURSOR 
LOCAL FAST_FORWARD
FOR  
SELECT name
FROM master.sys.databases
WHERE name IN ('AdventureWorksLT2019')
AND state_desc='online' 
OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @dbname  
WHILE @@FETCH_STATUS = 0  
BEGIN  

SELECT @statement = 'use '+@dbname +';'+ 'SELECT

ServerName=@@servername, dbname=db_name(db_id()),p.name as UserName, p.type_desc as TypeOfLogin, pp.name as PermissionLevel, pp.type_desc as TypeOfRole

FROM sys.database_role_members roles

JOIN sys.database_principals p ON roles.member_principal_id = p.principal_id

JOIN sys.database_principals pp ON roles.role_principal_id = pp.principal_id
where p.name =''sqldev'''  

EXEC sp_executesql @statement

FETCH NEXT FROM db_cursor INTO @dbname  
END  
CLOSE db_cursor  
DEALLOCATE db_cursor

SELECT
    db.name,
    db.is_encrypted,
    dm.encryption_state,
    dm.percent_complete,
    dm.key_algorithm,
    dm.key_length
FROM
    sys.databases db
    LEFT OUTER JOIN sys.dm_database_encryption_keys dm
        ON db.database_id = dm.database_id
WHERE db.name = 'AdventureWorksLT2019';
GO

--Chapter7
select '--Chapter7--';

SELECT
name AS FileName,
size*1.0/128 AS FileSizeinMB,
CASE max_size
WHEN 0 THEN 'Autogrowth is off.'
WHEN -1 THEN 'Autogrowth is on.'
ELSE 'Log file will grow to a maximum size of 2 TB.'
END AutogrowthStatus,
growth AS 'GrowthValue',
'GrowthIncrement' =
CASE
WHEN growth = 0 THEN 'Size is fixed and will not grow.'
WHEN growth > 0
AND is_percent_growth = 0
THEN 'Growth value is in 8-KB pages.'
ELSE 'Growth value is a percentage.'
END
FROM tempdb.sys.database_files;
GO
