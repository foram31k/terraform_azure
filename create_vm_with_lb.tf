provider "azurerm" {
   features {}
}

variable "prefix" {
  default = "terraformvmex"
}

#---------------------------------------------
# Resource group, Vnet, Subnet and NIC
#---------------------------------------------
resource "azurerm_resource_group" "example" {
  name     = "terraform_eg"
  location = "westus"
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.5"
  }
}

#--------------------------------------------------
# Virtual machines should be under Availability set
#--------------------------------------------------
resource "azurerm_availability_set" "example" {
  name                = "example-aset"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    environment = "Test"
  }
}

#------------------------------------------------------
# Resources to setup Load Balancer
#------------------------------------------------------
 resource "azurerm_public_ip" "example" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "example" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
#    sku                 = "Standard"
  }
}

#----------------------------------------------------
# Create VM under Availability set
#----------------------------------------------------
resource "azurerm_virtual_machine" "example" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_A1_v2"
  availability_set_id   = azurerm_availability_set.example.id #To set under availability set created above
  
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "tfvmeg"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "Test"
  }
}

#-----------------------------------------------------
# Add VM under Load balancer Backend pool
#-----------------------------------------------------
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "BackEndAddressPool"
}
resource "azurerm_network_interface_backend_address_pool_association" "example" {
  network_interface_id    = azurerm_network_interface.example.id
  ip_configuration_name   = "testconfiguration1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
}
