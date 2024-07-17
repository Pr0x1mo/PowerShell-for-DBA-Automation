# Define server instance and query to check if the SQL Server instance is running
$ServerInstance = "pr0x1mo.database.windows.net"
$InstanceCheckQuery = "SELECT @@SERVERNAME AS ServerName, SERVERPROPERTY('IsClustered') AS IsClustered, SERVERPROPERTY('IsHadrEnabled') AS IsHadrEnabled, SERVERPROPERTY('IsXTPSupported') AS IsXTPSupported"

# Function to send an email notification
function Send-EmailNotification {
    param (
        [string]$Subject,
        [string]$Body
    )
    $SmtpServer = "smtp.gmail.com"
    $SmtpPort = 587
    $Username = "xavierlborja@gmail.com"
    $SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
    $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

    $From = "xavierlborja@gmail.com"
    $To = "xavierlborja@gmail.com"

    Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credentials -From $From -To $To -Subject $Subject -Body $Body
}

# Check if the SQL Server instance is running
try {
    $InstanceCheckResult = Invoke-Sqlcmd -Query $InstanceCheckQuery -ServerInstance $ServerInstance

    # Check for issues with the instance status
    $IssuesFound = $false
    $IssueDetails = ""

    if ($InstanceCheckResult.ServerName -eq $null) {
        $IssuesFound = $true
        $IssueDetails += "Server instance is not running.`n"
    }

    if ($InstanceCheckResult.IsClustered -eq 0) {
        $IssuesFound = $true
        $IssueDetails += "Server instance is not clustered.`n"
    }

    if ($InstanceCheckResult.IsHadrEnabled -eq 0) {
        $IssuesFound = $true
        $IssueDetails += "HADR is not enabled.`n"
    }

    if ($InstanceCheckResult.IsXTPSupported -eq 0) {
        $IssuesFound = $true
        $IssueDetails += "In-Memory OLTP is not supported.`n"
    }

    # Additional checks for other tasks
    $OtherChecksQuery = @"
-- Check for session blocking
SELECT blocking_session_id, session_id FROM sys.dm_exec_requests WHERE blocking_session_id <> 0;

-- Check the error log for errors
EXEC xp_readerrorlog 0, 1, N'error';

-- Check for running DBMS jobs and their status
SELECT job.name AS JobName, job.originating_server AS Server, activity.run_requested_date AS RunRequestedDate, step.command AS Command
FROM msdb.dbo.sysjobs AS job
JOIN msdb.dbo.sysjobactivity AS activity ON job.job_id = activity.job_id
JOIN msdb.dbo.sysjobsteps AS step ON job.job_id = step.job_id
WHERE activity.stop_execution_date IS NULL;

-- Check the top session using more Physical I/O
SELECT TOP 10 r.session_id, r.logical_reads, r.reads, r.writes, r.cpu_time, r.total_elapsed_time
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
ORDER BY r.reads DESC;

-- Check the number of log switches per hour
SELECT database_name, COUNT(*) AS LogBackupCount, DATEPART(hour, backup_start_date) AS HourOfDay
FROM msdb.dbo.backupset WHERE type = 'L' GROUP BY database_name, DATEPART(hour, backup_start_date) ORDER BY HourOfDay;

-- Check how much redo was generated per hour
SELECT database_name, SUM(backup_size) AS TotalLogSize, DATEPART(hour, backup_start_date) AS HourOfDay
FROM msdb.dbo.backupset WHERE type = 'L' GROUP BY database_name, DATEPART(hour, backup_start_date) ORDER BY HourOfDay;

-- Detect locked objects
SELECT t.name AS TableName, resource_type, request_mode, request_status FROM sys.dm_tran_locks l JOIN sys.tables t ON l.resource_associated_entity_id = t.object_id WHERE resource_type = 'OBJECT';

-- Check SQL queries consuming a lot of resources
SELECT TOP 10 qs.sql_handle, qs.execution_count, qs.total_worker_time AS CPU_Time, qs.total_elapsed_time AS Total_Time, qs.total_logical_reads AS Reads, qs.total_logical_writes AS Writes, SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2) AS QueryText
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt ORDER BY qs.total_worker_time DESC;

-- Check the usage of memory in SQL Server
SELECT physical_memory_in_use_kb/1024 AS MemoryUsedMB, large_page_allocations_kb/1024 AS LargePageAllocationsMB, locked_page_allocations_kb/1024 AS LockedPageAllocationsMB, total_virtual_address_space_kb/1024 AS TotalVirtualAddressSpaceMB, virtual_address_space_reserved_kb/1024 AS VASReservedMB, virtual_address_space_committed_kb/1024 AS VASCommittedMB, virtual_address_space_available_kb/1024 AS VASAvailableMB, page_fault_count AS PageFaultCount FROM sys.dm_os_process_memory;

-- Display sessions using tempdb for rollback operations
SELECT s.session_id, s.host_name, s.program_name, s.login_name, r.status, r.command, r.wait_type, r.wait_time, r.blocking_session_id, r.percent_complete, r.estimated_completion_time FROM sys.dm_exec_requests r JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id WHERE r.database_id = DB_ID('tempdb');

-- Check buffer cache usage
SELECT COUNT(*) AS cached_pages_count, (COUNT(*) * 8.0 / 1024) AS cached_pages_size_MB FROM sys.dm_os_buffer_descriptors WHERE database_id = DB_ID('your_database_name');

-- Check buffer cache hit ratio
SELECT (1.0 - (CAST(c.cntr_value AS FLOAT) / (SELECT CAST(cntr_value AS FLOAT) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio' AND instance_name = '_Total'))) AS BufferCacheHitRatio FROM sys.dm_os_performance_counters AS c WHERE counter_name = 'Buffer cache hit ratio base';

-- Check backup status
SELECT database_name, backup_finish_date, backup_size, physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
ORDER BY backup_finish_date DESC;
"@

    $OtherChecksResult = Invoke-Sqlcmd -Query $OtherChecksQuery -ServerInstance $ServerInstance

    # Process the results of the additional checks
    if ($OtherChecksResult | Where-Object { $_.blocking_session_id }) {
        $IssuesFound = $true
        $IssueDetails += "Session blocking detected.`n"
    }

    if ($OtherChecksResult | Where-Object { $_.text -like '%error%' }) {
        $IssuesFound = $true
        $IssueDetails += "Errors found in the error log.`n"
    }

    if ($OtherChecksResult | Where-Object { $_.JobName }) {
        $IssuesFound = $true
        $IssueDetails += "Issues with running DBMS jobs.`n"
    }

    if ($OtherChecksResult | Where-Object { $_.TotalLogSize -gt 0 }) {
        $IssuesFound = $true
        $IssueDetails += "Redo log generated issues detected.`n"
    }

    # Add other necessary checks and conditions based on the result set
    # ...

    # If issues are found, send an email notification
    if ($IssuesFound) {
        Send-EmailNotification -Subject "SQL Server Instance Issue Detected" -Body "Issues were detected on the SQL Server instance $ServerInstance:`n$IssueDetails"
    } else {
        Write-Host "No issues detected with the SQL Server instance."
    }
} catch {
    # Catch any errors during the instance check and send an email notification
    $ErrorMessage = $_.Exception.Message
    Send-EmailNotification -Subject "SQL Server Instance Check Failed" -Body "An error occurred while checking the SQL Server instance $ServerInstance:`n$ErrorMessage"
}

# Define the query for automating common tasks, such as rebuilding indexes
$RebuildIndexesQuery = @"
-- Example query to automate a common task, such as rebuilding indexes
DECLARE @TableName NVARCHAR(256)
DECLARE @IndexName NVARCHAR(256)
DECLARE @SQL NVARCHAR(MAX)

DECLARE IndexCursor CURSOR FOR
SELECT OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id), i.name
FROM sys.indexes AS i
JOIN sys.tables AS t ON i.object_id = t.object_id
WHERE i.type_desc = 'NONCLUSTERED'

OPEN IndexCursor
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = N'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + @TableName + ' REBUILD;'
    EXEC sp_executesql @SQL
    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName
END

CLOSE IndexCursor
DEALLOCATE IndexCursor
"@

# Execute the query to rebuild indexes
Invoke-Sqlcmd -Query $RebuildIndexesQuery -ServerInstance $ServerInstance

# Perform a regular backup task
$BackupQuery = "BACKUP DATABASE my_database TO DISK = 'C:\Backups\my_database.bak';"
Invoke-Sqlcmd -Query $BackupQuery -ServerInstance $ServerInstance
