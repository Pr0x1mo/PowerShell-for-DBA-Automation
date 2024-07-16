# Reindex and Update Statistics in PostgreSQL Database and Send Email if Maintenance Fails
$psqlPath = "C:\Program Files\PostgreSQL\13\bin\psql.exe"
$Server = "localhost"
$Database = "your_database"
$User = "your_user"
$Password = "your_password"
$SmtpServer = "smtp.your-email-provider.com"
$SmtpFrom = "your-email@example.com"
$SmtpTo = "xavierlborja@gmail.com"
$Subject = "PostgreSQL Maintenance Issue Detected"
$Body = "There was an issue detected with the PostgreSQL maintenance."

$ReindexCommand = "$psqlPath -h $Server -U $User -d $Database -c `""REINDEX DATABASE $Database;`""
$AnalyzeCommand = "$psqlPath -h $Server -U $User -d $Database -c `""ANALYZE VERBOSE;`""

try {
    Invoke-Expression "& $ReindexCommand"
    Invoke-Expression "& $AnalyzeCommand"
    Write-Host "Maintenance completed successfully."
} catch {
    Write-Host "Maintenance failed."
    
    # Send an email notification
    Send-MailMessage -SmtpServer $SmtpServer -From $SmtpFrom -To $SmtpTo -Subject $Subject -Body $Body -Credential (Get-Credential -UserName 'your-email@example.com' -Message 'Enter your email password')
}
