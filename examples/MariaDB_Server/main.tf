module "mariadb" {
  source  = "kumarvna/mariadb/azurerm"
  version = "1.0.0"

  # By default, this module will create a resource group
  # proivde a name to use an existing resource group and set the argument 
  # to `create_resource_group = false` if you want to existing resoruce group. 
  # If you use existing resrouce group location will be the same as existing RG.
  create_resource_group = false
  resource_group_name   = "rg-shared-westeurope-01"
  location              = "westeurope"

  # MariaDB Server and Database settings
  mysqlserver_name = "mysqldbsrv01"

  mysqlserver_settings = {
    sku_name   = "GP_Gen5_16"
    storage_mb = 5120
    version    = "5.7"
    # default admin user `sqladmin` and can be specified as per the choice here
    # by default random password created by this module. required password can be specified here
    admin_username = "sqladmin"
    admin_password = "H@Sh1CoR3!"
    # Database name, charset and collection arguments  
    database_name = "demomysqldb"
    charset       = "utf8"
    collation     = "utf8_unicode_ci"
    # Storage Profile and other optional arguments
    auto_grow_enabled                 = true
    backup_retention_days             = 7
    geo_redundant_backup_enabled      = false
    infrastructure_encryption_enabled = false
    public_network_access_enabled     = true
    ssl_enforcement_enabled           = true
    ssl_minimal_tls_version_enforced  = "TLS1_2"
  }

}
