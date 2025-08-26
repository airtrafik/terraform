output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "gke_subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_id" {
  description = "ID of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "db_subnet_name" {
  description = "Name of the database subnet"
  value       = google_compute_subnetwork.db_subnet.name
}

output "valkey_subnet_name" {
  description = "Name of the Valkey subnet"
  value       = google_compute_subnetwork.valkey_subnet.name
}

output "private_service_connection" {
  description = "Private service connection for managed services"
  value       = google_service_networking_connection.private_service_connection.service
}