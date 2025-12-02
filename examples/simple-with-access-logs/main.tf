module "bucket" {
  source     = "../../"
  project_id = "zeus-404008"
  labels = {
    cloud       = "gcp"
    component   = "access-logs"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name                      = "simple-bucket"
  create_access_logs_bucket = true
}