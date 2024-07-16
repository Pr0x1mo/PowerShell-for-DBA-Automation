# Monitor SQL Agent Jobs

# Variables
$ServerName = "your-sql-server.database.windows.net"
$DatabaseName = "master"
$User = "your-username"
$Password = "your-password"
$SmtpServer = "smtp.your-email-provider.com"
$SmtpFrom = "your-email@example.com"
$SmtpTo = "xavierlborja@gmail.com"
$Subject = "SQL Agent Job Failure Notification"
$Body = "One or more SQL Agent jobs have failed."

# Save the email password securely
$SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
$Credential = New-Object System.Management.Automation.PSCredential("your-email@example.com", $SecurePassword)

# Monitor SQL Agent Jobs
$Jobs = Invoke-Sqlcmd -Query "SELECT name, last_run_date, last_run_time, last_run_outcome FROM msdb.dbo.sysjobs" -ServerInstance $ServerName -Database $DatabaseName -Username $User -Password $Password

foreach ($Job in $Jobs) {
    if ($Job.last_run_outcome -ne 1) {
        Write-Host "Job $($Job.name) failed."
        
        # Send an email notification
        Send-MailMessage -SmtpServer $SmtpServer -From $SmtpFrom -To $SmtpTo -Subject $Subject -Body $Body -Credential $Credential
    }
}
