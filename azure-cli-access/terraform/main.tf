data "azurerm_subscription" "current" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name_suffix = random_string.suffix.result
  rg_name     = "${var.prefix}-rg-${local.name_suffix}"
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
}

# User-assigned managed identity that the Teleport Application Service will assume
# on behalf of users running `tsh az ...` commands.
resource "azurerm_user_assigned_identity" "teleport" {
  name                = var.prefix
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# Reader role on the resource group so the identity can list/inspect resources.
# Per the Teleport docs, broader privileges should be granted only as needed.
resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.teleport.principal_id
}

# Storage Blob Data Contributor lets the identity read/write blob data via AAD
# (data plane). Use to test whether `tsh az storage blob ...` flows through.
resource "azurerm_role_assignment" "blob_data_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.teleport.principal_id
}

# Storage Account Contributor lets the identity manage accounts and fetch keys
# (control plane). Required for `az storage account keys list`.
resource "azurerm_role_assignment" "storage_account_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.teleport.principal_id
}

# Test storage account + container used to verify Teleport Azure CLI behavior
# for both control plane (account/keys/containers) and data plane (blob bytes).
resource "azurerm_storage_account" "test" {
  name                            = "tpaz${local.name_suffix}${substr(replace(var.prefix, "-", ""), 0, 10)}"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
}

resource "azurerm_storage_container" "test" {
  name                  = "teleport-test"
  storage_account_name  = azurerm_storage_account.test.name
  container_access_type = "private"
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_interface" "this" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# Cloud-init bootstrap. The VM joins the Teleport cluster via the Azure delegated
# join method using its attached user-assigned managed identity, so no static
# token needs to be placed on the host.
locals {
  proxy_host = split(":", var.teleport_proxy_address)[0]

  cloud_init = <<-CLOUDINIT
    #cloud-config
    write_files:
      - path: /etc/teleport.yaml
        permissions: '0644'
        content: |
          version: v3
          teleport:
            join_params:
              method: azure
              token_name: ${var.teleport_join_token_name}
              azure:
                client_id: ${azurerm_user_assigned_identity.teleport.client_id}
            proxy_server: "${var.teleport_proxy_address}"
          auth_service:
            enabled: false
          proxy_service:
            enabled: false
          ssh_service:
            enabled: true
          app_service:
            enabled: true
            apps:
              - name: ${var.teleport_app_name}
                cloud: Azure
    runcmd:
      - curl -fsSL "https://${local.proxy_host}/scripts/install.sh" | bash
      - systemctl enable teleport
      - systemctl restart teleport
  CLOUDINIT
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${var.prefix}-vm"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.admin_ssh_public_key_path))
  }

  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.teleport.id]
  }

  custom_data = base64encode(local.cloud_init)
}
