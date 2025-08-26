# Staging Environment Configuration
project_id   = "airtrafik-staging"
project_name = "airtrafik"
region       = "us-west1"

# GKE Configuration - Better resources for staging
gke_system_machine_type = "n2-standard-2"
gke_system_min_nodes    = 1
gke_system_max_nodes    = 3

gke_app_machine_type = "n2-standard-4"
gke_app_min_nodes    = 2
gke_app_max_nodes    = 4

gke_preemptible = false

# Database Configuration - Better for staging
db_tier              = "db-g1-small"
db_high_availability = false
db_disk_size         = 20

# Valkey Configuration - Better for staging
valkey_tier        = "BASIC"
valkey_memory_size = 2

# Uncomment and add your network for GKE master access
# authorized_networks = [
#   {
#     cidr_block   = "YOUR_IP/32"
#     display_name = "Developer Access"
#   }
# ]

# State bucket already created
create_state_bucket = false