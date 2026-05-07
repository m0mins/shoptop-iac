#output "acm_cert_frontend_arn" {
#  value = module.acm_cert_frontend.arn
#}

output "acm_cert_frontend_arn" {
  value = module.acm_cert_frontend.acm_certificate_arn
}
