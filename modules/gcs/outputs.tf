output "uploads_bucket_name" {
  description = "Name of the uploads bucket"
  value       = google_storage_bucket.uploads.name
}

output "uploads_bucket_url" {
  description = "URL of the uploads bucket"
  value       = google_storage_bucket.uploads.url
}

output "backups_bucket_name" {
  description = "Name of the backups bucket"
  value       = google_storage_bucket.backups.name
}

output "backups_bucket_url" {
  description = "URL of the backups bucket"
  value       = google_storage_bucket.backups.url
}

output "terraform_state_bucket_name" {
  description = "Name of the terraform state bucket"
  value       = var.create_state_bucket ? google_storage_bucket.terraform_state[0].name : ""
}