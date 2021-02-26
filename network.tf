resource "azurerm_public_ip" "pip1" {
  name                = "vm-pip1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = ["10.22.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet1-sub1" {
  name                 = "vnet1-sub1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.22.0.0/24"]
}

resource "azurerm_network_interface" "netint1" {
  name                = "vm01-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet1-sub1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.22.0.4"
    public_ip_address_id          = azurerm_public_ip.pip1.id

  }
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "nsg1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_network_security_group_association" "nsgsub1" {
  subnet_id                 = azurerm_subnet.vnet1-sub1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_security_rule" "RDPRule" {
  name                        = "Allow_RDP"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 203
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 3389
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg1.name
}
