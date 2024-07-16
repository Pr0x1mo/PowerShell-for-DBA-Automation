# Performance monitoring script using Azure CLI

# Variables
resourceGroupName="your-resource-group"
sqlServerName="your-sql-server"
databaseName="your-database"

# Login to Azure
az login

# Get performance metrics
az monitor metrics list --resource "/subscriptions/your-subscription-id/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$sqlServerName/databases/$databaseName" --metric "cpu_percent,dtu_consumption_percent" --interval PT1H
