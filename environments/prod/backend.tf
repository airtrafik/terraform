terraform {
  backend "gcs" {
    # State bucket hosted in airtrafik-ops project for centralized state management
    bucket = "airtrafik-terraform-state"
    prefix = "prod"
  }
}