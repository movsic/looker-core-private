output "ip_address" {
  value = google_compute_address.lb_address.address
}