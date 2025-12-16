module "bucket" {
  source      = "../../"
  project_id  = "zeus-404008"
  customer    = "nurdsoft"
  environment = "dev"
  labels = {
    cloud     = "gcp"
    component = "bucket"
  }
  name = "simple-bucket"
}
