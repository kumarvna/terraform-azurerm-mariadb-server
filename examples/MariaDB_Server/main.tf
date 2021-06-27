module "mariadb-server" {
  source  = "kumarvna/mariadb-server/azurerm"
  version = "1.0.0"

  # By default, this module will create a resource group
  # proivde a name to use an existing resource group and set the argument 
  # to `create_resource_group = false` if you want to existing resoruce group. 
  # If you use existing resrouce group location will be the same as existing RG.
  create_resource_group = false
  resource_group_name   = "rg-shared-westeurope-01"
  location              = "westeurope"

  # MariaDB Server and Database settings
  mariadb_server_name = "mariadbsqlsrv01"

  mariadb_settings = {
    sku_name   = "GP_Gen5_16"
    storage_mb = 5120
    version    = "10.2"
    # default admin user `sqladmin` and can be specified as per the choice here
    # by default random password created by this module. required password can be specified here
    admin_username = "sqladmin"
    admin_password = "H@Sh1CoR3!"
    # Database name, charset and collection arguments  
    database_name = "demomariadb01"
    charset       = "utf8"
    collation     = "utf8_unicode_ci"
    # Storage Profile and other optional arguments
    auto_grow_enabled             = true
    backup_retention_days         = 7
    geo_redundant_backup_enabled  = false
    public_network_access_enabled = true
    ssl_enforcement_enabled       = true
  }

  # Sets a MariaDB Configuration value on a MariaDB Server.
  # For more information: https://mariadb.com/kb/en/server-system-variables/
  mariadb_configuration = {
    interactive_timeout = "600"
  }

  # Use Virtual Network service endpoints and rules for Azure Database for MariaDB
  subnet_id = var.subnet_id

  # (Optional) To enable Azure Monitoring for Azure MariaDB database
  # (Optional) Specify `enable_logs_to_storage_account` to save monitoring logs to storage. 
  # Create required storage account by specifying optional `storage_account_name` variable. 
  log_analytics_workspace_name   = "loganalytics-we-sharedtest2"
  enable_logs_to_storage_account = true
  storage_account_name           = "mariadblogdignostics"

  # Firewall Rules to allow azure and external clients and specific Ip address/ranges. 
  firewall_rules = {
    access-to-azure = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    },
    desktop-ip = {
      start_ip_address = "49.204.228.223"
      end_ip_address   = "49.204.228.223"
    }
  }

  # Tags for Azure Resources
  tags = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "test-user"
  }
}
