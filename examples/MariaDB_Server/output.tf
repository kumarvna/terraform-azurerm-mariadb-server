output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = module.mariadb.resource_group_name
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = module.mariadb.resource_group_location
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = module.mariadb.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.mariadb.storage_account_name
}

output "mariadb_server_id" {
  description = "The resource ID of the MariaDB Server"
  value       = module.mariadb.mariadb_server_id
}

output "mariadb_server_fqdn" {
  description = "The FQDN of the MariaDB Server"
  value       = module.mariadb.mariadb_server_fqdn
}

output "mariadb_database_id" {
  description = "The resource ID of the MariaDB Database"
  value       = module.mariadb.mariadb_database_id
}

