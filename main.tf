
# Data block to reference existing Resource Group
data "azurerm_resource_group" "existing_rg" {
  name = "todorg"
}

# Data block to reference existing Virtual Network
data "azurerm_virtual_network" "existing_vnet" {
  name                = "todo_vnet"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

# Data block to reference existing Subnet
data "azurerm_subnet" "existing_subnet" {
  name                 = "todo_subnet"
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_resource_group.existing_rg.name
}


# Create Public IP
resource "azurerm_public_ip" "linux_vm_ip" {
  name                = "linuxVM-ip"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  allocation_method   = "Static"
}

# Create NIC for VM
resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "linuxVM-nic"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_vm_ip.id
  }
}

#Create Linux VM
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                  = "forntendvm"
  location              = data.azurerm_resource_group.existing_rg.location
  resource_group_name   = data.azurerm_resource_group.existing_rg.name
  size                  = "Standard_B1s"
  admin_username        = "devops"
  admin_password        = "devops@12345"  # Use ssh key in production
  network_interface_ids = [azurerm_network_interface.linux_vm_nic.id]

  disable_password_authentication = false

  os_disk {
    name                 = "linuxOSDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
              apt-get update
              apt-get install -y docker-ce
              systemctl enable docker
              systemctl start docker

              # Pull and run docker container (replace nginx with your own image if needed)
              docker run -d -p 80:80 nginx
            EOF
  )



}


# # more rg add
resource "azurerm_resource_group" "rg" {
  name = "debu"
  location ="centralindia"
  
}