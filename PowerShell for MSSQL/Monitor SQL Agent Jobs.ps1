# Monitor SQL Agent Jobs
$ServerInstance = "pr0x1mo.database.windows.net"
$Jobs = Invoke-Sqlcmd -Query "SELECT name, last_run_date, last_run_time, last_run_outcome FROM msdb.dbo.sysjobs" -ServerInstance $ServerInstance

foreach ($Job in $Jobs) {
    if ($Job.last_run_outcome -ne 1) {
        Write-Host "Job $($Job.name) failed."

        # Send an email notification
        $SmtpServer = "smtp.gmail.com"
        $SmtpPort = 587
        $Username = "xavierlborja@gmail.com"
        $SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
        $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

        $From = "xavierlborja@gmail.com"
        $To = "xavierlborja@gmail.com"
        $Subject = "SQL Agent Job Failure Notification"
        $Body = "Job $($Job.name) failed on server $ServerInstance. Last run date: $($Job.last_run_date), Last run time: $($Job.last_run_time)."

        Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl -Credential $Credentials -From $From -To $To -Subject $Subject -Body $Body
    }
}
