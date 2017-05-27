variable network_name {}

# Network
resource "google_compute_network" "kn-network" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "true"
}

# Firewall external rules
resource "google_compute_firewall" "kn-firewall-external" {
  name          = "${var.network_name}-firewall-external"
  network       = "${google_compute_network.kn-network.name}"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"

    ports = [
      "22",  # SSH
      "80",  # HTTP
      "443",
    ] # HTTPS
  }
}

# Firewall internal rules
resource "google_compute_firewall" "kn-firewall-internal" {
  name          = "${var.network_name}-firewall-internal"
  network       = "${google_compute_network.kn-network.name}"
  source_ranges = ["10.128.0.0/9"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

output "network_name" {
  value = "${google_compute_network.kn-network.name}"
}
