module "this" {
  source    = "cloudposse/label/null"
  version   = "0.25.0"
  stage     = var.stage
  namespace = var.project_namespace
}