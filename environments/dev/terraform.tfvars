# Development Environment Configuration
project_id   = "airtrafik-dev"
project_name = "airtrafik"
region       = "us-west1"

# GKE Configuration - Minimal for dev
gke_system_machine_type = "n2-standard-2"
gke_system_min_nodes    = 1
gke_system_max_nodes    = 2

gke_app_machine_type = "n2-standard-2"
gke_app_min_nodes    = 1
gke_app_max_nodes    = 3

gke_preemptible = true

# Database Configuration - Minimal for dev
db_tier              = "db-f1-micro"
db_high_availability = false
db_disk_size         = 10

# Valkey Configuration - Minimal for dev
valkey_tier        = "BASIC"
valkey_memory_size = 1

# Uncomment and add your network for GKE master access
# authorized_networks = [
#   {
#     cidr_block   = "YOUR_IP/32"
#     display_name = "Developer Access"
#   }
# ]

# Set to true on first run to create state bucket
create_state_bucket = false