output "google_compute_global_ip_address" {
  value       = google_compute_global_address.compute_global_address[*].address
  description = "Reserved External IP address"
}