output "vcn_server_private_ips" {
  value = aws_instance.server.*.private_ip
}

output "vcn_server_public_ips" {
  value = aws_instance.server[*].public_ip
}

output "nomad_client_private_ips" {
  value = aws_instance.client.*.private_ip
}

output "nomad_client_public_ips" {
  value = aws_instance.client[*].public_ip
}

output "fqdn_tls" {
  value = local.fqdn_tls  
}

# output "fqdn_tls-2" {
#   value = tostring(local.fqdn_tls)  
# }

output "fqdn_tls_consul" {
  value = local.consul_fqdn_tls  
}

# output "consul_cert_dns" {
#   value = concat(local.fqdn_tls, local.consul_fqdn_tls)
  
# # }
# output "consul_dns_names" { 
# value = setunion(local.fqdn_tls, local.consul_fqdn_tls)
# }