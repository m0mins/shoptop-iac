#module "acm_request_certificate_backend" {
#  source = "cloudposse/acm-request-certificate/aws"
#  # Cloud Posse recommends pinning every module to a specific version
#  version     = "0.18.0"
#  domain_name = terraform.workspace == "prod" ? "${var.cluster_domain}" : "${var.stage}.${var.cluster_domain}"
#  #   process_domain_validation_options = true
#  ttl                       = "300"
#  subject_alternative_names = []
#  zone_id                   = var.zone_id
#}