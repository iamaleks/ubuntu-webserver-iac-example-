# Basic configuration withour variables

# Define authentification configuration
provider "vsphere" {
  # If you use a domain set your login like this "MyDomain\\MyUser"
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

#### RETRIEVE DATA INFORMATION ON VCENTER ####

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter_name
}

data "vsphere_resource_pool" "pool" {
  # If you haven't resource pool, put "Resources" after cluster name
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = var.vsphere_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information on vsphere
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve network information on vsphere
data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve template information on vsphere
data "vsphere_virtual_machine" "template" {
  name          = "template_ubuntu18"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#### VM CREATION ####

# Set vm parameters
resource "vsphere_virtual_machine" "webserver-vm" {
  name             = var.vm_name
  num_cpus         = 2
  memory           = 4096
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type

  # Set network parameters
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  # Use a predefined vmware template has main disk
  disk {
    label = "webserver.vmdk"
    size = "30"
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "TerraformWebserver"
        domain    = var.domain
      }

      network_interface {
        ipv4_address    = var.ip_address
        ipv4_netmask    = var.netmask
      }

      ipv4_gateway = var.def_gw
      dns_server_list = var.dns_server

    }
  }

  # Execute script on remote vm after this creation
  # Execute script on remote vm after this creation
  provisioner "remote-exec" {
    script = "scripts/install-webserver.sh"
    connection {
      type     = "ssh"
      user     = var.ssh_username
      password = var.ssh_password
      host     = var.ip_address
    }
  }
}

