# 1. Configure the Azure provider
provider "azurerm" {
  features {}
}

# 2. Create a Resource Group
resource "azurerm_resource_group" "example" {
  name     = "Hemant_devops_casestudy"
  location = "Central India"  # Choose your preferred location
}

# 3. Create a Virtual Network (VNet)
resource "azurerm_virtual_network" "example" {
  name                = "vnet-terraform-example"
  address_space       = ["10.0.0.0/16"]  # Define IP address range
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# 4. Create a Subnet within the VNet
resource "azurerm_subnet" "example" {
  name                 = "subnet-terraform-example"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]  # Define IP address range for subnet
}

# 5. Create a Network Security Group (NSG) with an SSH rule (for Linux VM)
resource "azurerm_network_security_group" "example" {
  name                = "nsg-terraform-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"  # SSH port for Linux VM
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 6. Create a Public IP for the VM
resource "azurerm_public_ip" "example" {
  name                = "public-ip-terraform-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"  # Change this from "Dynamic" to "Static"
  sku                  = "Standard"  # Ensure you are using the "Standard" SKU
}

# 7. Create a Network Interface (NIC)
resource "azurerm_network_interface" "example" {
  name                      = "nic-terraform-example"
  location                  = azurerm_resource_group.example.location
  resource_group_name       = azurerm_resource_group.example.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id  # Link subnet here
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id  # Link public IP
  }

  depends_on = [azurerm_subnet.example]  # Ensures subnet is created before NIC
}

# 8. Associate NSG with NIC using azurerm_network_interface_security_group_association
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# 9. Create a Linux Virtual Machine with password authentication
resource "azurerm_linux_virtual_machine" "example" {
  name                = "Node1"  # VM name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"  # VM size
  admin_username      = "HemuPatil"  # Admin username
  disable_password_authentication = false  # Allow password authentication

  # Specify the admin password to authenticate to the VM
  admin_password = "Heman*1234"  # Set a strong password for the VM

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"  # Disk caching mode
    storage_account_type = "Standard_LRS"  # Storage type for the OS disk
  }

  source_image_reference {
    publisher = "Canonical"  # Publisher for Ubuntu images
    offer     = "UbuntuServer"  # Offer for Ubuntu Linux OS
    sku       = "18.04-LTS"  # Choose the Ubuntu version (e.g., 18.04-LTS)
    version   = "latest"  # Use the latest version of the image
  }

  tags = {
    environment = "development"
  }
}

# 10. Output the public IP of the VM
output "public_ip" {
  value = azurerm_public_ip.example.ip_address
}
