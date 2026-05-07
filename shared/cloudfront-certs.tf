
module "acm_cert_frontend" {
  source = "cloudposse/acm-request-certificate/aws"
  providers = {
    aws = aws.virginia
  }

  # Cloud Posse recommends pinning every module to a specific version
  version = "0.18.0"
  #zone_id                           = aws_route53_zone.frontend.zone_id
  #domain_name                       = "strativ-support.se"
  domain_name                       = "demo.strativ-support.se"
  #subject_alternative_names         = ["dev.strativ-support.se"]
  subject_alternative_names = []
  #validate_certificate = true
#  validation_method                 = "EMAIL" # email validation instead
  validation_method = "DNS"
  process_domain_validation_options = false
  ttl                               = "600"
  context                           = module.shoptop.context
}




#module "acm_cert_frontend" {
#  source = "cloudposse/acm-request-certificate/aws"
#  providers = {
#    aws = aws.virginia
#  }
#
#  version = "0.18.0"
#
#  domain_name               = "static.support-strativ.se"  # your actual subdomain
#  subject_alternative_names = []
#
#  validate_certificate = true
#
#  process_domain_validation_options = false  # disable automatic DNS validation (you're not using Route 53)
#  validation_method                 = "EMAIL" # email validation instead
#  ttl                               = "300"
#
#  context = module.shoptop.context
#}
#