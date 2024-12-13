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

# 7. Create a Network Interface (NIC) and associate NSG
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

# 8. Create a Linux Virtual Machine with SSH Key Authentication
resource "azurerm_linux_virtual_machine" "example" {
  name                = "Node1"  # VM name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"  # VM size
  admin_username      = "HemuPatil"  # Admin username
  disable_password_authentication = true  # Disable password authentication (use SSH keys)

  # Specify the admin SSH key for authentication
  admin_ssh_key {
    username   = "HemuPatil"  # Username must match admin_username
    public_key = file("C:/Users/hemant.patil/.ssh/id_rsa.pub")  # Path to your SSH public key
  }

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"  # Disk caching mode
    storage_account_type = "Standard_LRS"  # Storage type for the OS disk
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = "development"
  }
}

# 9. Output the public IP of the VM
output "public_ip" {
  value = azurerm_public_ip.example.ip_address
}
