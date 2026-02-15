output "instance_name" {
  description = "Jenkins instance name"
  value       = google_compute_instance.jenkins.name
}

output "instance_id" {
  description = "Jenkins instance ID"
  value       = google_compute_instance.jenkins.id
}

output "instance_self_link" {
  description = "Jenkins instance self link"
  value       = google_compute_instance.jenkins.self_link
}

output "private_ip" {
  description = "Jenkins VM private IP address"
  value       = google_compute_instance.jenkins.network_interface[0].network_ip
}

output "data_disk_name" {
  description = "Jenkins data disk name"
  value       = google_compute_disk.jenkins_data.name
}
