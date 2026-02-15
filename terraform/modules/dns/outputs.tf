output "zone_name" {
  description = "DNS zone name"
  value       = google_dns_managed_zone.private_zone.name
}

output "zone_dns_name" {
  description = "DNS zone DNS name"
  value       = google_dns_managed_zone.private_zone.dns_name
}

output "jenkins_fqdn" {
  description = "Jenkins fully qualified domain name"
  value       = trimsuffix(google_dns_record_set.jenkins_a_record.name, ".")
}
