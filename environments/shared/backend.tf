terraform {
  backend "gcs" {
    bucket = "airtrafik-terraform-state"
    prefix = "shared"
  }
}
