# Monitor PostgreSQL Database Connections and Send Email if Issues Found
$Server = "localhost"
$Database = "your_database"
$User = "your_user"
$Password = "your_password"
$ConnectionString = "Host=$Server;Username=$User;Password=$Password;Database=$Database"
$query = "SELECT * FROM pg_stat_activity;"
$SmtpServer = "smtp.your-email-provider.com"
$SmtpFrom = "your-email@example.com"
$SmtpTo = "xavierlborja@gmail.com"
$Subject = "PostgreSQL Connection Issue Detected"
$Body = "There was an issue detected with the PostgreSQL connections."

# Execute the query and display the results
$Jobs = Invoke-Sqlcmd -ConnectionString $ConnectionString -Query $query

foreach ($Job in $Jobs) {
    if ($Job.state -ne 'active') {
        Write-Host "Issue detected with connection: $($Job.datname)"
        
        # Send an email notification
        Send-MailMessage -SmtpServer $SmtpServer -From $SmtpFrom -To $SmtpTo -Subject $Subject -Body $Body -Credential (Get-Credential -UserName 'your-email@example.com' -Message 'Enter your email password')
    }
}
