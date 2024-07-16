# Automate maintenance tasks using PowerShell

# Variables
$ServerName = "your-sql-server.database.windows.net"
$DatabaseName = "your-database"
$User = "your-username"
$Password = "your-password"
$SmtpServer = "smtp.your-email-provider.com"
$SmtpFrom = "your-email@example.com"
$SmtpTo = "xavierlborja@gmail.com"
$Subject = "Azure SQL Maintenance Notification"
$Body = "Maintenance tasks completed successfully."

# Save the email password securely
$SecurePassword = Get-Content "C:\Secure\password.txt" | ConvertTo-SecureString
$Credential = New-Object System.Management.Automation.PSCredential("your-email@example.com", $SecurePassword)

# Connect to Azure SQL Database
$Conn = New-Object System.Data.SqlClient.SqlConnection
$Conn.ConnectionString = "Server=tcp:$ServerName,1433;Initial Catalog=$DatabaseName;Persist Security Info=False;User ID=$User;Password=$Password;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$Conn.Open()

# Perform maintenance tasks
$Command = $Conn.CreateCommand()
$Command.CommandText = "EXEC sp_updatestats;"
$Command.ExecuteNonQuery()

# Send an email notification
Send-MailMessage -SmtpServer $SmtpServer -From $SmtpFrom -To $SmtpTo -Subject $Subject -Body $Body -Credential $Credential

$Conn.Close()
