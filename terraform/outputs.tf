output "vm_ips" {
  description = "IP addresses of all created VMs"
  value = {
    jumphost      = "10.0.10.102, 192.168.100.5"
    dns_server    = "10.0.10.53, 192.168.100.53"
    ngrok-tunnel  = "10.0.10.60, 192.168.100.60"
    k3s-master    = "192.168.100.10"
    k3s-worker-1  = "192.168.100.11"
    k3s-worker-2  = "192.168.100.12"
    jenkins       = "192.168.100.20"
    sonarqube     = "192.168.100.30"
	nexus         = "192.168.100.31"
    harbor	      = "192.168.100.32"
    prometeus     = "192.168.100.40"
  }
}

output "vm_ids" {
  description = "VM IDs of all created VMs"
  value = {
    jumphost      = 200
    dns_server    = 201
    ngrok-tunnel  = 202
    k3s-master    = 210
    k3s-worker-1  = 211
    k3s-worker-2  = 212
    jenkins       = 220
    sonarqube     = 221
    nexus         = 222
    harbor        = 223
	monitoring    = 224
  }
}

output "ssh_commands" {
  description = "SSH connection commands"
  value = {
	jumphost      = "ssh admin@10.0.10.102  # или ssh admin@192.168.100.5"
    dns_server    = "ssh admin@10.0.10.53  # или ssh admin@192.168.100.53"
    ngrok-tunnel  = "ssh admin@10.0.10.60  # или ssh admin@192.168.100.60"
    k3s-master    = "ssh admin@192.168.100.10"
    k3s-worker-1  = "ssh admin@192.168.100.11"
    k3s-worker-2  = "ssh admin@192.168.100.12"
    jenkins       = "ssh admin@192.168.100.20"
    sonarqube     = "ssh admin@192.168.100.30"
    nexus         = "ssh admin@192.168.100.31"
	harbor        = "ssh admin@192.168.100.32"
    monitoring    = "ssh admin@192.168.100.40"
    
  }
}

output "vm_roles" {
  description = "Roles and purposes of all created VMs"
  value = {
    jumphost      = "Management Jump Host"
    dns_server    = "DNS Server"
    ngrok-tunnel  = "Tunnel Gateway"
    k3s-master    = "K3s Control Plane"
    k3s-worker-1  = "K3s Worker"
    k3s-worker-2  = "K3s Worker"
    jenkins       = "CI Server"
    sonarqube     = "Code Quality"
    nexus         = "Artifact Repository"
    harbor        = "Container Registry"
	monitoring    = "Prometheus+Grafana"
  }
}

output "network_summary" {
  description = "Network configuration summary"
  value = {
    external_network = "10.0.10.0/24 (vmbr0)"
    internal_network = "192.168.100.0/24 (vmbr1)"
    dual_homed_vms   = "dns-server, ngrok-tunnel, jumphost"
    internal_only_vms = "k3s-master, k3s-worker-1, k3s-worker-2, jenkins, sonarqube, nexus, harbor, monitoring"
  }
}