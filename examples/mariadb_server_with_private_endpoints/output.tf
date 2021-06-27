output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = module.mariadb-server.resource_group_name
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = module.mariadb-server.resource_group_location
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = module.mariadb-server.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.mariadb-server.storage_account_name
}

output "mariadb_server_id" {
  description = "The resource ID of the MariaDB Server"
  value       = module.mariadb-server.mariadb_server_id
}

output "mariadb_server_fqdn" {
  description = "The FQDN of the MariaDB Server"
  value       = module.mariadb-server.mariadb_server_fqdn
}

output "mariadb_database_id" {
  description = "The resource ID of the MariaDB Database"
  value       = module.mariadb-server.mariadb_database_id
}

output "mariadb_server_private_endpoint" {
  description = "id of the MariaDB server Private Endpoint"
  value       = module.mariadb-server.mariadb_server_private_endpoint
}

output "mariadb_server_private_dns_zone_domain" {
  description = "DNS zone name of MariaDB server Private endpoints dns name records"
  value       = module.mariadb-server.mariadb_server_private_dns_zone_domain
}

output "mariadb_server_private_endpoint_ip" {
  description = "MariaDB server private endpoint IPv4 Addresses "
  value       = module.mariadb-server.mariadb_server_private_endpoint_ip
}

output "mariadb_server_private_endpoint_fqdn" {
  description = "MariaDB server private endpoint FQDN Addresses "
  value       = module.mariadb-server.mariadb_server_private_endpoint_fqdn
}
