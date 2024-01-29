#specify providers source and version to use
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}
#configure the provider being used
provider "azurerm" {
  features {}
}

#create a resource group and set tags 
resource "azurerm_resource_group" "db-rg" {
  name     = "db-rg01"
  location = "East US"
  tags = {
    environment = "dev"
  }
}

####Resource Group Role Assignment

resource "azurerm_role_assignment" "db-rg" {

  scope = azurerm_resource_group.db-rg.id

  role_definition_name = "Reader"

  principal_id = "f7d4cbb5-9560-4c42-9583-b59ece855ae4"

}

#create an azure virtual network
resource "azurerm_virtual_network" "db-vn" {
  name                = "db-vn01"
  address_space       = ["10.123.0.0/16"]
  location            = azurerm_resource_group.db-rg.location
  resource_group_name = azurerm_resource_group.db-rg.name
  tags = {
    environment = "dev"
  }
}
#create an azure subnet network
resource "azurerm_subnet" "db-subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.db-rg.name
  virtual_network_name = azurerm_virtual_network.db-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}
#create an azure network security group to control traffic flow
resource "azurerm_network_security_group" "db-nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.db-rg.location
  resource_group_name = azurerm_resource_group.db-rg.name
  tags = {
    environment = "dev"
  }
}
#Creates basic rules for the NSG 
resource "azurerm_network_security_rule" "db-dev-rule" {
  name                        = "db-dev-rule"
  priority                    = 100
  direction                   = "inbound"
  access                      = "allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.db-rg.name
  network_security_group_name = azurerm_network_security_group.db-nsg.name
}
#creates a public IP address to access the VM to be created externally via the internet
resource "azurerm_public_ip" "db-pub-ip" {
  name                = "db-pub-ip"
  location            = azurerm_resource_group.db-rg.location
  resource_group_name = azurerm_resource_group.db-rg.name
  allocation_method   = "Dynamic"
  tags = {
    environment = "dev"
  }
}

#creates a network interface to provide connectivity from the public IP created above
resource "azurerm_network_interface" "db-nic" {
  name                = "db-nic01"
  location            = azurerm_resource_group.db-rg.location
  resource_group_name = azurerm_resource_group.db-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.db-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.db-pub-ip.id
  }
  tags = {
    environment = "dev"
  }
}
#creates the most important object of the this template which is the VM instance, also specifying a way to securely login via SSH key stored on your remote machine
resource "azurerm_linux_virtual_machine" "db-vm" {
  name                  = "db-VM01"
  resource_group_name   = azurerm_resource_group.db-rg.name
  location              = azurerm_resource_group.db-rg.location
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.db-nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/dbazurekey.pub")

  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


