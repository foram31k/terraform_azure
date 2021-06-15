provider "azurerm" {
   features {}
}

#--------------------------------------------
# Pass all the data required 
#--------------------------------------------
data "azurerm_virtual_network" "example" {
  name                = "terraformvmex-network"
  resource_group_name = "terraform_eg"
}
data "azurerm_lb" "example" {
  name                = "TestLoadBalancer"
  resource_group_name = "terraform_eg"
}

data "azurerm_lb_backend_address_pool" "example" {
  name            = "BackEndAddressPool"
  loadbalancer_id = data.azurerm_lb.example.id
}

#Add Vm in Load balancer's backend pool
resource "azurerm_lb_backend_address_pool_address" "example" {
  name                    = "BackEndAddressPool"
  backend_address_pool_id = data.azurerm_lb_backend_address_pool.example.id
  virtual_network_id      = data.azurerm_virtual_network.example.id
  ip_address              = "10.0.2.5" # Private IP of VM to be added in backend Pool
} 
