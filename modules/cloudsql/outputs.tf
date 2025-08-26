output "instance_name" {
  description = "The name of the database instance"
  value       = google_sql_database_instance.postgres.name
}

output "instance_connection_name" {
  description = "The connection name of the database instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip_address" {
  description = "The private IP address of the database instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.database.name
}

output "database_user" {
  description = "The database user"
  value       = google_sql_user.app_user.name
}

output "database_password_secret_id" {
  description = "The Secret Manager secret ID containing database credentials"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "database_password_secret_version" {
  description = "The Secret Manager secret version containing database credentials"
  value       = google_secret_manager_secret_version.db_password.name
}