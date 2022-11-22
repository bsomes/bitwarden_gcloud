terraform {
    required_providers {
      google = {
          source = "hashicorp/google"
          version = "4.17.0"
      }
    }
}

provider "google" {
  
}

locals {
  project_id = "vaultwarden-347603"
}

data "google_project" "project" {
  project_id = local.project_id
}

resource "google_service_account" "default" {
  account_id = "vaultwarden-service-account"
  display_name = "Service Account"

  project = local.project_id
}

resource "google_compute_instance" "vm" {
    name = "main-vm"
    machine_type = "e2-micro"
    zone = var.zone

    project = local.project_id

    tags = ["http-server", "https-server"]

    boot_disk {
      initialize_params {
          image = "cos-cloud/cos-stable"
          size = 30
      }
    }

    network_interface {
      network = "default"
      access_config {
        // Make an ephemeral ip address
      }
    }

    metadata = {
      "ssh-keys" = "${var.user}:${file("~/.ssh/vaultwarden_instance.pub")}"
    }

    metadata_startup_script = file("../utilities/reboot-on-update.sh")

    service_account {
      scopes = ["compute-rw"]
    }

    provisioner "file" {
      source = pathexpand("../bitwarden")
      destination = "/home/${var.user}/bitwarden"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance") 
      }
    }

    provisioner "file" {
      source = pathexpand("../caddy")
      destination = "/home/${var.user}/caddy"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance") 
      }
    }

    provisioner "file" {
      source = pathexpand("../countryblock")
      destination = "/home/${var.user}/countryblock"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance") 
      }
    }

    provisioner "file" {
      source = pathexpand("../fail2ban")
      destination = "/home/${var.user}/fail2ban"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance") 
      }
    }

    provisioner "file" {
      source = pathexpand("../utilities")
      destination = "/home/${var.user}/utilities"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance") 
      }
    }

    provisioner "file" {
      source = pathexpand("../docker-compose.yml")
      destination = "/home/${var.user}/docker-compose.yml"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance")
      }
    }

    provisioner "file" {
      source = pathexpand("../ddns")
      destination = "/home/${var.user}/ddns"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance")
      }
    }

    provisioner "file" {
      source = pathexpand("../rclone")
      destination = "/home/${var.user}/rclone"

      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance")
      }
    }

    provisioner "remote-exec" {
      inline = ["sh", "/home/${var.user}/utilities/install-alias.sh"]
      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance")
      }
    }

    provisioner "remote-exec" {
      inline = ["docker-compose", "up", "-d"]
      connection {
        type = "ssh"
        user = var.user
        host = self.network_interface.0.access_config.0.nat_ip
        private_key = file("~/.ssh/vaultwarden_instance")
      }
    }
}

resource "google_compute_firewall" "firewall_rules" {
  name = "firewall-rules"
  network = "default"
  description = "allow traffic on port 80 and 443"

  project = local.project_id

  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }

  source_ranges = ["0.0.0.0"]
  target_tags = ["http-server"]
}