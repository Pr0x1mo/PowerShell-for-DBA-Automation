# Restore SQL Server Database
$ServerInstance = "pr0x1mo.database.windows.net"
$Database = "proximo"
$BackupPath = "C:\Backups\proximo.bak"

Invoke-Sqlcmd -Query "RESTORE DATABASE [$Database] FROM DISK = N'$BackupPath' WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10" -ServerInstance $ServerInstance

# Send email notification after restore
$SmtpServer = "smtp.gmail.com"
$SmtpPort = 587
$Username = "xavierlborja@gmail.com"
$SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
$Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

$From = "xavierlborja@gmail.com"
$To = "xavierlborja@gmail.com"
$Subject = "SQL Server Database Restore Notification"
$Body = "The restore of database $Database on server $ServerInstance has been completed successfully."

Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credentials -From $From -To $To -Subject $Subject -Body $Body
