variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = true
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = ""
}

variable "log_analytics_workspace_name" {
  description = "The name of log analytics workspace name"
  default     = null
}

variable "random_password_length" {
  description = "The desired length of random password created by this module"
  default     = 24
}

variable "mariadb_server_name" {
  description = "Name of the MariaDB server"
  default     = ""
}

variable "admin_username" {
  description = "The administrator login name for the new SQL Server"
  default     = null
}

variable "admin_password" {
  description = "The password associated with the admin_username user"
  default     = null
}

variable "mariadb_settings" {
  description = "MariaDB server settings"
  type = object({
    sku_name                      = string
    version                       = string
    storage_mb                    = number
    auto_grow_enabled             = optional(bool)
    backup_retention_days         = optional(number)
    geo_redundant_backup_enabled  = optional(bool)
    public_network_access_enabled = optional(bool)
    ssl_enforcement_enabled       = bool
    create_mode                   = optional(string)
    creation_source_server_id     = optional(any)
    restore_point_in_time         = optional(any)
    database_name                 = string
    charset                       = string
    collation                     = string
  })
}

variable "storage_account_name" {
  description = "The name of the storage account name"
  default     = null
}

variable "mariadb_configuration" {
  description = "Sets a MariaDB Configuration value on a MariaDB Server"
  type        = map(string)
  default     = {}
}

variable "firewall_rules" {
  description = "Range of IP addresses to allow firewall connections."
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = null
}

variable "subnet_id" {
  description = "The resource ID of the subnet"
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
