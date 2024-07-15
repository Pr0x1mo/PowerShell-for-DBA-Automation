# Troubleshoot SQL Server Logs
$ServerInstance = "pr0x1mo.database.windows.net"
$Logs = Invoke-Sqlcmd -Query "EXEC xp_readerrorlog" -ServerInstance $ServerInstance

# Filter and analyze logs
$FilteredLogs = $Logs | Where-Object { $_ -like "*Error*" }

# Save filtered logs to file
$FilteredLogs | Out-File "C:\Logs\SQLServerErrors.log"

# Send an email notification if there are errors
if ($FilteredLogs) {
    $SmtpServer = "smtp.gmail.com"
    $SmtpPort = 587
    $Username = "xavierlborja@gmail.com"
    $SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
    $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

    $From = "xavierlborja@gmail.com"
    $To = "xavierlborja@gmail.com"
    $Subject = "SQL Server Error Log Notification"
    $Body = "Errors were found in the SQL Server logs on server $ServerInstance. Please check the attached log file for details."

    # Send email with log file attachment
    Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credentials -From $From -To $To -Subject $Subject -Body $Body -Attachments "C:\Logs\SQLServerErrors.log"
}
