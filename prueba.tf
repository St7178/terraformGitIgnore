# Configuración del proveedor de Azure
provider "azurerm" {
  features {}
  subscription_id = "414276b4-1a1d-4cb0-a6bd-eecaff36224a"
}

# Definición del recurso de grupo de recursos
resource "azurerm_resource_group" "example" {
  name     = "pruebaTerraform"
  location = "East US 2"
}

# Definición de la red virtual
resource "azurerm_virtual_network" "example" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Definición de la subred
resource "azurerm_subnet" "example" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Definición del grupo de seguridad de red (NSG)
resource "azurerm_network_security_group" "example" {
  name                = "myNSG"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  # Regla para permitir RDP (puerto 3389) desde cualquier lugar (Internet)
  security_rule {
    name                       = "Allow-RDP"
    priority                  = 100
    direction                 = "Inbound"
    access                    = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "3389"  # Puerto para RDP
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

# Asociar el NSG a la subred
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# Crear una IP pública para la máquina virtual
resource "azurerm_public_ip" "example" {
  name                         = "myPublicIP"
  location                     = azurerm_resource_group.example.location
  resource_group_name          = azurerm_resource_group.example.name
  allocation_method            = "Dynamic" # IP dinámica
  sku                          = "Basic"
}

# Definición de la interfaz de red
resource "azurerm_network_interface" "example" {
  name                = "myNIC"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "myNICConfiguration"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id  # Asociar la IP pública
  }
}

# Definición de la máquina virtual Windows
resource "azurerm_virtual_machine" "example" {
  name                  = "myVM"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_B1s"  

  storage_os_disk {
    name              = "myOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"  # Imagen de Windows Server 2019
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "superadm"
    admin_password = "Compunet123."
  }

  os_profile_windows_config {
    provision_vm_agent = true  # Habilitar agente de VM para gestión remota
    enable_automatic_upgrades = true  # Habilitar actualizaciones automáticas
  }
}
