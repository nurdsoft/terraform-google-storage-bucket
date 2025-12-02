module "bucket" {
  source     = "../../"
  project_id = "zeus-404008"
  labels = {
    cloud       = "gcp"
    component   = "bucket"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name = "simple-bucket"
}