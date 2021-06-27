#------------------------------------------------------------
# Local configuration - Default (required). 
#------------------------------------------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
  mysqlserver_settings = defaults(var.mariadb_settings, {
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

data "azurerm_log_analytics_workspace" "logws" {
  count               = var.log_analytics_workspace_name != null ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = local.resource_group_name
}

#---------------------------------------------------------
# Storage Account to keep Audit logs - Default is "false"
#----------------------------------------------------------
resource "random_string" "str" {
  count   = var.enable_logs_to_storage_account != true && var.log_analytics_workspace_name != null ? 1 : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    name = var.storage_account_name
  }
}

resource "azurerm_storage_account" "storeacc" {
  count                     = var.enable_logs_to_storage_account == true && var.log_analytics_workspace_name != null ? 1 : 0
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
    administrator_login_password = var.mariadb_server_name
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

#------------------------------------------------------------
# Adding  MariaDB Server Parameters - Default is "false"
#------------------------------------------------------------
resource "azurerm_mariadb_configuration" "main" {
  for_each            = var.mariadb_configuration != null ? { for k, v in var.mariadb_configuration : k => v if v != null } : {}
  name                = each.key
  resource_group_name = local.resource_group_name
  server_name         = azurerm_mariadb_server.main.name
  value               = each.value
}

#------------------------------------------------------------
# Adding Firewall rules for MariaDB Server - Default is "false"
#------------------------------------------------------------
resource "azurerm_mariadb_firewall_rule" "main" {
  for_each            = var.firewall_rules != null ? { for k, v in var.firewall_rules : k => v if v != null } : {}
  name                = format("%s", each.key)
  resource_group_name = local.resource_group_name
  server_name         = azurerm_mariadb_server.main.name
  start_ip_address    = each.value["start_ip_address"]
  end_ip_address      = each.value["end_ip_address"]
}

#------------------------------------------------------------------------------------
# Allowing traffic between an Azure MariaDB server and a subnet - Default is "false"
#------------------------------------------------------------------------------------
resource "azurerm_mariadb_virtual_network_rule" "main" {
  count               = var.subnet_id != null ? 1 : 0
  name                = format("%s-vnet-rule", var.mariadb_server_name)
  resource_group_name = local.resource_group_name
  server_name         = azurerm_mariadb_server.main.name
  subnet_id           = var.subnet_id
}

#---------------------------------------------------------
# Private Link for MariaDB Server - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "vnet01" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

resource "azurerm_subnet" "snet-ep" {
  count                                          = var.enable_private_endpoint ? 1 : 0
  name                                           = "snet-endpoint-shared-${local.location}"
  resource_group_name                            = local.resource_group_name
  virtual_network_name                           = data.azurerm_virtual_network.vnet01.0.name
  address_prefixes                               = var.private_subnet_address_prefix
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_private_endpoint" "pep1" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-private-endpoint", var.mariadb_server_name)
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = azurerm_subnet.snet-ep.0.id
  tags                = merge({ "Name" = format("%s-private-endpoint", var.mariadb_server_name) }, var.tags, )

  private_service_connection {
    name                           = "sqldbprivatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mariadb_server.main.id
    subresource_names              = ["mariadbServer"]
  }
}

data "azurerm_private_endpoint_connection" "private-ip1" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_private_endpoint.pep1.0.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_mariadb_server.main]
}

resource "azurerm_private_dns_zone" "dnszone1" {
  count               = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.mariadb.database.azure.com"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "MySQL-Private-DNS-Zone") }, var.tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "vent-link1" {
  count                 = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                  = "vnet-private-zone-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnszone1.0.name
  virtual_network_id    = data.azurerm_virtual_network.vnet01.0.id
  tags                  = merge({ "Name" = format("%s", "vnet-private-zone-link") }, var.tags, )
}

resource "azurerm_private_dns_a_record" "arecord1" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = azurerm_mariadb_server.main.name
  zone_name           = var.existing_private_dns_zone == null ? azurerm_private_dns_zone.dnszone1.0.name : var.existing_private_dns_zone
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.private-ip1.0.private_service_connection.0.private_ip_address]
}

#------------------------------------------------------------------
# azurerm monitoring diagnostics  - Default is "false" 
#------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "extaudit" {
  count                      = var.log_analytics_workspace_name != null ? 1 : 0
  name                       = lower("extaudit-${var.mariadb_server_name}-diag")
  target_resource_id         = azurerm_mariadb_server.main.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.logws.0.id
  storage_account_id         = var.enable_logs_to_storage_account == true ? element(concat(azurerm_storage_account.storeacc.*.id, [""]), 0) : null

  dynamic "log" {
    for_each = var.extaudit_diag_logs
    content {
      category = log.value
      enabled  = true
      retention_policy {
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [log, metric]
  }
}
