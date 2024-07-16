# PowerShell script to create a database backup

# Variables
$ResourceGroupName = "your-resource-group"
$ServerName = "your-sql-server"
$DatabaseName = "your-database"
$StorageAccountName = "yourstorageaccount"
$StorageKey = "your-storage-account-key"
$ContainerName = "your-container"

# Login to Azure
Connect-AzAccount

# Create a credential for the storage account
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey

# Backup the database
New-AzSqlDatabaseImportExportStatus -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -StorageUri "https://$StorageAccountName.blob.core.windows.net/$ContainerName/$DatabaseName.bacpac" -StorageKeyType "StorageAccessKey" -StorageKey $StorageKey
