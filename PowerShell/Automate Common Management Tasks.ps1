# Automate Common Management Tasks
$ServerInstance = "pr0x1mo.database.windows.net"
$Query = @"
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

Invoke-Sqlcmd -Query $Query -ServerInstance $ServerInstance

# Send email notification after task completion
$SmtpServer = "smtp.gmail.com"
$SmtpPort = 587
$Username = "xavierlborja@gmail.com"
$SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
$Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

$From = "xavierlborja@gmail.com"
$To = "xavierlborja@gmail.com"
$Subject = "SQL Server Management Task Notification"
$Body = "The automated management task on server $ServerInstance has been completed successfully."

Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credentials -From $From -To $To -Subject $Subject -Body $Body
