# Production Environment Configuration
project_id   = "airtrafik-prod"
project_name = "airtrafik"
region       = "us-west1"

# GKE Configuration - Production ready
gke_system_machine_type = "n2-standard-2"
gke_system_min_nodes    = 2
gke_system_max_nodes    = 4

gke_app_machine_type = "n2-standard-4"
gke_app_min_nodes    = 3
gke_app_max_nodes    = 10

gke_preemptible = false

# Database Configuration - Production
db_tier              = "db-n1-standard-2"
db_high_availability = true
db_disk_size         = 50

# Valkey Configuration - Production with HA
valkey_tier        = "STANDARD_HA"
valkey_memory_size = 5

# Uncomment and add your network for GKE master access
# authorized_networks = [
#   {
#     cidr_block   = "YOUR_OFFICE_IP/32"
#     display_name = "Office Network"
#   }
# ]

# State bucket already created
create_state_bucket = false