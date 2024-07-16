# Backup PostgreSQL Database and Send Email if Backup Fails
$pgDumpPath = "C:\Program Files\PostgreSQL\13\bin\pg_dump.exe"
$BackupFile = "C:\Backups\your_database_backup.bak"
$Server = "localhost"
$Database = "your_database"
$User = "your_user"
$Password = "your_password"
$SmtpServer = "smtp.your-email-provider.com"
$SmtpFrom = "your-email@example.com"
$SmtpTo = "xavierlborja@gmail.com"
$Subject = "PostgreSQL Backup Issue Detected"
$Body = "There was an issue detected with the PostgreSQL backup."

$BackupCommand = "$pgDumpPath -h $Server -U $User -d $Database -F c -b -v -f $BackupFile"

try {
    Invoke-Expression "& $BackupCommand"
    Write-Host "Backup completed successfully."
} catch {
    Write-Host "Backup failed."
    
    # Send an email notification
    Send-MailMessage -SmtpServer $SmtpServer -From $SmtpFrom -To $SmtpTo -Subject $Subject -Body $Body -Credential (Get-Credential -UserName 'your-email@example.com' -Message 'Enter your email password')
}
