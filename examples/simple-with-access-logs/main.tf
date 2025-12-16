module "bucket" {
  source      = "../../"
  project_id  = "zeus-404008"
  customer    = "nurdsoft"
  environment = "dev"
  labels = {
    cloud     = "gcp"
    component = "access-logs"
  }
  name                      = "simple-bucket"
  create_access_logs_bucket = true
}
