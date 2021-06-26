#------------------------------------------------------------
# Local configuration - Default (required). 
#------------------------------------------------------------
locals {
  resource_group_name                = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location                           = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
  if_threat_detection_policy_enabled = var.enable_threat_detection_policy ? [{}] : []
  mysqlserver_settings = defaults(var.mysqlserver_settings, {
    charset   = "utf8"
    collation = "utf8_general_ci"
  })
}

#---------------------------------------------------------
# Resource Group Creation or selection - Default is "false"
#----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = merge({ "Name" = format("%s", var.resource_group_name) }, var.tags, )
}

data "azurerm_client_config" "current" {}

data "azurerm_log_analytics_workspace" "logws" {
  count               = var.log_analytics_workspace_name != null ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = local.resource_group_name
}

#---------------------------------------------------------
# Storage Account to keep Audit logs - Default is "false"
#----------------------------------------------------------

resource "random_string" "str" {
  count   = var.enable_threat_detection_policy ? 1 : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    name = var.storage_account_name
  }
}

resource "azurerm_storage_account" "storeacc" {
  count                     = var.enable_threat_detection_policy ? 1 : 0
  name                      = var.storage_account_name == null ? "stsqlauditlogs${element(concat(random_string.str.*.result, [""]), 0)}" : substr(var.storage_account_name, 0, 24)
  resource_group_name       = local.resource_group_name
  location                  = local.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  tags                      = merge({ "Name" = format("%s", "stsqlauditlogs") }, var.tags, )
}

resource "random_password" "main" {
  count       = var.admin_password == null ? 1 : 0
  length      = var.random_password_length
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    administrator_login_password = var.mysqlserver_name
  }
}

#----------------------------------------------------------------
# Adding  MariaDB Server creation and settings - Default is "True"
#-----------------------------------------------------------------
resource "azurerm_mariadb_server" "main" {
  name                          = format("%s", var.mariadb_server_name)
  resource_group_name           = local.resource_group_name
  location                      = local.location
  administrator_login           = var.admin_username == null ? "sqladmin" : var.admin_username
  administrator_login_password  = var.admin_password == null ? random_password.main.0.result : var.admin_password
  sku_name                      = var.mariadb_settings.sku_name
  storage_mb                    = var.mariadb_settings.storage_mb
  version                       = var.mariadb_settings.version
  auto_grow_enabled             = var.mariadb_settings.auto_grow_enabled
  backup_retention_days         = var.mariadb_settings.backup_retention_days
  create_mode                   = var.mariadb_settings.create_mode
  creation_source_server_id     = var.mariadb_settings.create_mode != "Default" ? var.mariadb_settings.creation_source_server_id : null
  restore_point_in_time         = var.mariadb_settings.create_mode == "PointInTimeRestore" ? var.mariadb_settings.restore_point_in_time : null
  geo_redundant_backup_enabled  = var.mariadb_settings.geo_redundant_backup_enabled
  public_network_access_enabled = var.mariadb_settings.public_network_access_enabled
  ssl_enforcement_enabled       = var.mariadb_settings.ssl_enforcement_enabled
  tags                          = merge({ "Name" = format("%s", var.mariadb_server_name) }, var.tags, )
}

#------------------------------------------------------------
# Adding  MariaDB Server Database - Default is "true"
#------------------------------------------------------------
resource "azurerm_mariadb_database" "main" {
  name                = var.mariadb_settings.database_name
  resource_group_name = local.resource_group_name
  server_name         = azurerm_mariadb_server.main.name
  charset             = var.mariadb_settings.charset
  collation           = var.mariadb_settings.collation
}

