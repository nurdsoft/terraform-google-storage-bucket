module "bucket" {
  source      = "../../"
  project_id  = "virendra-test-459520"
  customer    = "nurdsoft"
  environment = "dev"
  labels = {
    cloud     = "gcp"
    component = "static-site"
  }
  name                      = "dev"
  domain_name               = "nurdsoft.co"
  create_access_logs_bucket = true
  create_load_balancer      = true
  enable_secure_connection  = true
  use_aws_route53           = true # Enable AWS Route53 record creation

  backend_bucket = {
    default = {
      enable_cdn = true
      cdn_policy = {
        cache_mode  = "CACHE_ALL_STATIC"
        default_ttl = 3600
        client_ttl  = 7200
        max_ttl     = 10800
        cache_key_policy = {
          include_http_headers   = [""]
          query_string_whitelist = [""]
        }
        bypass_cache_on_request_headers = {
          header_name = false
        }
      }
    }
  }
}
