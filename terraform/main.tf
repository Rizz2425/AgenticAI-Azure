# 1. Azure Provider Setup
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Resource Group (Ek container saari resources ke liye)
resource "azurerm_resource_group" "django_rg" {
  name     = "django-ai-resources"
  location = "Central India" # Mumbai ke pass Azure ka region
}

# 3. Virtual Network Setup
resource "azurerm_virtual_network" "django_vnet" {
  name                = "django-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.django_rg.location
  resource_group_name = azurerm_resource_group.django_rg.name
}

resource "azurerm_subnet" "django_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.django_rg.name
  virtual_network_name = azurerm_virtual_network.django_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Public IP 
resource "azurerm_public_ip" "django_public_ip" {
  name                = "django-public-ip"
  resource_group_name = azurerm_resource_group.django_rg.name
  location            = azurerm_resource_group.django_rg.location
  allocation_method   = "Static"   
  sku                 = "Standard"
}


# 5. Network Interface (Isme NSG link hona zaroori hai)
resource "azurerm_network_interface" "django_nic" {
  name                = "django-nic"
  location            = azurerm_resource_group.django_rg.location
  resource_group_name = azurerm_resource_group.django_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.django_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.django_public_ip.id
  }
}

# 6. Security Group (SSH aur Django ke liye)
resource "azurerm_network_security_group" "django_nsg" {
  name                = "django-nsg"
  location            = azurerm_resource_group.django_rg.location
  resource_group_name = azurerm_resource_group.django_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Django"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# YE WALI LINE ZAROORI HAI: NIC ko NSG se jodne ke liye
resource "azurerm_network_interface_security_group_assignment" "nic_nsg_link" {
  network_interface_id      = azurerm_network_interface.django_nic.id
  network_security_group_id = azurerm_network_security_group.django_nsg.id
}

# ... (VM aur baaki code same rahega)

# 7. Virtual Machine (Ubuntu)
resource "azurerm_linux_virtual_machine" "django_vm" {
  name                = "DjangoServer-Azure"
  resource_group_name = azurerm_resource_group.django_rg.name
  location            = azurerm_resource_group.django_rg.location
  size                = "Standard_B2ats_v2"
  admin_username      = "ubuntu"
  network_interface_ids = [
    azurerm_network_interface.django_nic.id,
  ]

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("azure_key.pub") # Ab ye terraform folder ke andar se uthayega
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF
  )
}

# 8. Output IP Address
output "instance_ip" {
  value = azurerm_public_ip.django_public_ip.ip_address
}