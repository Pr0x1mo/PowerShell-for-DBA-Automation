# Save the password securely in a file
$Password = "YourEmailPassword" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString | Out-File "C:\Secure\password.txt"

