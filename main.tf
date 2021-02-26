resource "azurerm_resource_group" "rg" {
  location = "northeurope"
  name     = "tftest-mssql-rg"
}

resource "azurerm_windows_virtual_machine" "vm01" {
  name                = "vm01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "randomadmin"
  admin_password      = "4_pwAdm42!"
  network_interface_ids = [
    azurerm_network_interface.netint1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2017-WS2016"
    sku       = "SQLDEV"
    version   = "latest"
  }
}

# ----------- DISKS --------------------------------

resource "azurerm_managed_disk" "sql_data" {
  name                 = "sql_data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql_data" {
  virtual_machine_id = azurerm_windows_virtual_machine.vm01.id
  managed_disk_id    = azurerm_managed_disk.sql_data.id
  lun                = 0
  caching            = "None"
}

resource "azurerm_managed_disk" "sql_log" {
  name                 = "sql_log"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql_log" {
  virtual_machine_id = azurerm_windows_virtual_machine.vm01.id
  managed_disk_id    = azurerm_managed_disk.sql_log.id
  lun                = 1
  caching            = "None"
}

resource "azurerm_managed_disk" "sql_tempdb" {
  name                 = "sql_tempdb"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
}

resource "azurerm_virtual_machine_data_disk_attachment" "sql_tempdb" {
  virtual_machine_id = azurerm_windows_virtual_machine.vm01.id
  managed_disk_id    = azurerm_managed_disk.sql_tempdb.id
  lun                = 2
  caching            = "ReadOnly"
}

# ----------- MSSQL --------------------------------

resource "azurerm_mssql_virtual_machine" "mssql_vm01" {
  virtual_machine_id               = azurerm_windows_virtual_machine.vm01.id
  sql_license_type                 = "PAYG"
  r_services_enabled               = true
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = "Password1234!"
  sql_connectivity_update_username = "sqllogin"

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "OLTP"
    data_settings {
      default_file_path = "X:\\Data"
      luns              = [azurerm_virtual_machine_data_disk_attachment.sql_data.lun]
    }
    log_settings {
      default_file_path = "Y:\\TLog"
      luns              = [azurerm_virtual_machine_data_disk_attachment.sql_log.lun]
    }
    temp_db_settings {
      default_file_path = "Z:\\TempDb"
      luns              = [azurerm_virtual_machine_data_disk_attachment.sql_tempdb.lun]
    }
  }
}
