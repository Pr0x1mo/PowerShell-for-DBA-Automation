# Add a new PostgreSQL User and Send Email if Creation Fails
$psqlPath = "C:\Program Files\PostgreSQL\13\bin\psql.exe"
$Server = "localhost"
$Database = "your_database"
$User = "your_user"
$Password = "your_password"
$NewUser = "new_user"
$NewPassword = "new_password"
$SmtpServer = "smtp.your-email-provider.com"
$SmtpFrom = "your-email@example.com"
$SmtpTo = "xavierlborja@gmail.com"
$Subject = "PostgreSQL User Creation Issue Detected"
$Body = "There was an issue detected with the PostgreSQL user creation."

$AddUserCommand = "$psqlPath -h $Server -U $User -d $Database -c `""CREATE USER $NewUser WITH PASSWORD '$NewPassword';`""

try {
    Invoke-Expression "& $AddUserCommand"
    Write-Host "User created successfully."
} catch {
    Write-Host "User creation failed."
    
    # Send an email notification
    Send-MailMessage -SmtpServer $SmtpServer -From $SmtpFrom -To $SmtpTo -Subject $Subject -Body $Body -Credential (Get-Credential -UserName 'your-email@example.com' -Message 'Enter your email password')
}
