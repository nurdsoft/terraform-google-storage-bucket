# ------------------------------------------------------------------------------
# Storage Bucket
# ------------------------------------------------------------------------------
locals {
  default_name                  = "${var.customer}-${var.environment}"
  fqdn                          = var.create_load_balancer == true ? (var.name == "" ? coalesce(var.domain_name, var.default_domain_name) : "${var.name}.${coalesce(var.domain_name, var.default_domain_name)}") : var.name
  fqdn_managed_ssl_certificates = [local.fqdn, "www.${local.fqdn}"]
  ssl                           = var.create_load_balancer == true && var.enable_secure_connection == true
  redirect_to_https             = var.create_load_balancer == true && var.redirect_to_https == true
  default_domain                = var.create_load_balancer == true && var.domain_name == ""
  custom_domain                 = var.create_load_balancer == true && var.domain_name != ""
  website_domain_name_dashed    = replace(local.fqdn, ".", "-")
  bucket_kms_keys               = var.bucket_kms_key_name == "" ? [] : [var.bucket_kms_key_name]
  access_log_kms_keys           = var.access_logs_kms_key_name == "" ? [] : [var.access_logs_kms_key_name]
  google_compute_backend_bucket = "web-bucket-${local.default_name}"
  website_root_domain           = coalesce(var.domain_name, var.default_domain_name)
  global_address_name           = "web-lb-ip-${local.default_name}"
  ssl_certificate_name          = "web-ssl-${local.default_name}"
  https_compute_url_map         = "web-urlmap-https-${local.default_name}"
  https_target_proxy_name       = "web-proxy-https-${local.default_name}"
  https_forwarding_rule_name    = "web-forwarding-rule-https-${local.default_name}"
  http_compute_url_map          = "web-url-map-http-${local.default_name}"
  http_target_proxy_name        = "web-proxy-http-${local.default_name}"
  http_forwarding_rule_name     = "web-rule-http-${local.default_name}"
}

module "storage_bucket" {
  source                   = "./modules/bucket"
  name                     = local.fqdn
  project_id               = var.project_id
  location                 = var.bucket_location
  storage_class            = var.bucket_storage_class
  bucket_policy_only       = var.bucket_policy_only
  labels                   = merge(var.bucket_labels, var.labels)
  force_destroy            = var.force_destroy_bucket
  public_access_prevention = var.public_access_prevention
  enable_versioning        = var.enable_versioning
  enable_autoclass         = var.enable_autoclass
  retention_policy         = var.retention_policy
  encryption               = var.encryption
  website                  = var.create_load_balancer == true ? var.website_default_map : {}
  cors                     = var.cors
  custom_placement_config  = var.custom_placement_config
  lifecycle_rules          = var.lifecycle_rules
  log_bucket               = var.create_access_logs_bucket ? module.logs_bucket[0].name : null
  log_object_prefix        = var.access_log_prefix != "" ? var.access_log_prefix : local.website_domain_name_dashed
  enable_public_access     = var.enable_public_access
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SEPARATE BUCKET TO STORE ACCESS LOGS
# ---------------------------------------------------------------------------------------------------------------------
module "logs_bucket" {
  source             = "./modules/bucket"
  count              = var.create_access_logs_bucket ? 1 : 0
  name               = "${local.website_domain_name_dashed}-logs"
  project_id         = var.project_id
  location           = var.bucket_location
  storage_class      = var.bucket_storage_class
  force_destroy      = var.force_destroy_access_logs_bucket
  bucket_policy_only = var.bucket_policy_only
  labels             = merge(var.bucket_labels, var.labels)
  encryption         = var.encryption
  lifecycle_rules    = var.log_bucket_lifecycle_rules
}

resource "google_compute_backend_bucket" "compute_backend_bucket" {
  for_each                = var.create_load_balancer ? var.backend_bucket : {}
  provider                = google
  project                 = var.project_id
  name                    = local.google_compute_backend_bucket
  bucket_name             = module.storage_bucket.name
  description             = lookup(each.value, "description", null)
  enable_cdn              = lookup(each.value, "enable_cdn", false)
  compression_mode        = lookup(each.value, "compression_mode", "DISABLED")
  custom_response_headers = lookup(each.value, "custom_response_headers", [])

  dynamic "cdn_policy" {
    for_each = each.value.enable_cdn ? [1] : []
    content {
      cache_mode                   = each.value.cdn_policy.cache_mode
      signed_url_cache_max_age_sec = each.value.cdn_policy.signed_url_cache_max_age_sec
      default_ttl                  = each.value.cdn_policy.default_ttl
      max_ttl                      = each.value.cdn_policy.max_ttl
      client_ttl                   = each.value.cdn_policy.client_ttl
      negative_caching             = each.value.cdn_policy.negative_caching
      serve_while_stale            = each.value.cdn_policy.serve_while_stale

      dynamic "negative_caching_policy" {
        for_each = each.value.cdn_policy.negative_caching_policy != null ? [1] : []
        content {
          code = each.value.cdn_policy.negative_caching_policy.code
          ttl  = each.value.cdn_policy.negative_caching_policy.ttl
        }
      }

      dynamic "cache_key_policy" {
        for_each = each.value.cdn_policy.cache_key_policy != null ? [1] : []
        content {
          query_string_whitelist = each.value.cdn_policy.cache_key_policy.query_string_whitelist
          include_http_headers   = each.value.cdn_policy.cache_key_policy.include_http_headers
        }
      }

      dynamic "bypass_cache_on_request_headers" {
        for_each = each.value.cdn_policy.bypass_cache_on_request_headers != null ? [1] : []
        content {
          header_name = each.value.cdn_policy.bypass_cache_on_request_headers.header_name
        }
      }
    }
  }
}

# Reserve an external IP
resource "google_compute_global_address" "compute_global_address" {
  count    = var.create_load_balancer ? 1 : 0
  provider = google
  name     = local.global_address_name
  project  = var.project_id
}

# Get the GCP managed DNS zone - Not Tested
data "google_dns_managed_zone" "dns_managed_zone" {
  count    = local.custom_domain && var.use_google_dns ? 1 : 0
  provider = google
  name     = var.domain_name
  project  = var.project_id
}

# Add the IP to the GCP DNS - Not Tested
resource "google_dns_record_set" "dns_records" {
  count        = local.custom_domain && var.use_google_dns ? length(local.fqdn_managed_ssl_certificates) : 0
  provider     = google
  name         = local.fqdn_managed_ssl_certificates[count.index]
  type         = var.dns_record_type
  ttl          = var.dns_record_ttl
  managed_zone = data.google_dns_managed_zone.dns_managed_zone[0].name
  rrdatas      = [google_compute_global_address.compute_global_address[0].address]
}

# If no domain_name is provided, fetch the existing Route53 zone
data "aws_route53_zone" "route53_zone" {
  count        = local.default_domain ? 1 : 0
  name         = var.default_domain_name
  private_zone = var.dns_zone_private
}

# Fetch AWS Route53 zone for custom domain when using AWS Route53
data "aws_route53_zone" "aws_custom_domain_zone" {
  count        = var.use_aws_route53 && local.custom_domain ? 1 : 0
  name         = var.domain_name
  private_zone = var.dns_zone_private
}

# If no domain_name is provided, create an A record in the existing Route53 zone
resource "aws_route53_record" "default" {
  count   = local.default_domain ? 1 : 0
  zone_id = data.aws_route53_zone.route53_zone[0].zone_id
  name    = local.fqdn
  type    = var.dns_record_type
  ttl     = var.dns_record_ttl
  records = [google_compute_global_address.compute_global_address[0].address]
}

# If no domain_name is provided, add a friendly DNS name to the default record
resource "aws_route53_record" "custom" {
  count   = local.default_domain ? 1 : 0
  zone_id = data.aws_route53_zone.route53_zone[0].zone_id
  name    = "www.${aws_route53_record.default[0].name}"
  type    = "CNAME"
  ttl     = var.dns_record_ttl
  records = [local.fqdn]
}

# AWS Route53 records for custom domain management
# Create A record for the main domain when using AWS Route53
resource "aws_route53_record" "aws_main_domain" {
  count   = var.use_aws_route53 && local.custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.aws_custom_domain_zone[0].zone_id
  name    = var.name == "" ? var.domain_name : "${var.name}.${var.domain_name}"
  type    = "A"
  ttl     = var.dns_record_ttl
  records = [google_compute_global_address.compute_global_address[0].address]
}

# Create A record for www subdomain when using AWS Route53
resource "aws_route53_record" "aws_www_subdomain" {
  count   = var.use_aws_route53 && local.custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.aws_custom_domain_zone[0].zone_id
  name    = var.name == "" ? "www.${var.domain_name}" : "www.${var.name}.${var.domain_name}"
  type    = "A"
  ttl     = var.dns_record_ttl
  records = [google_compute_global_address.compute_global_address[0].address]
}

resource "random_id" "certificate" {
  count       = var.random_certificate_suffix == true && local.ssl ? 1 : 0
  byte_length = 4
  prefix      = "${local.ssl_certificate_name}-cert-"

  keepers = {
    domains = join(",", local.fqdn_managed_ssl_certificates)
  }
}

resource "google_compute_managed_ssl_certificate" "compute_managed_ssl_certificate" {
  provider = google-beta
  project  = var.project_id
  count    = length(local.fqdn_managed_ssl_certificates) > 0 && local.ssl ? 1 : 0
  name     = var.random_certificate_suffix == true ? random_id.certificate[0].hex : "${local.ssl_certificate_name}-cert"

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = local.fqdn_managed_ssl_certificates
  }
}

# LB URL MAP
resource "google_compute_url_map" "http-redirect" {
  count   = local.redirect_to_https ? 1 : 0
  project = var.project_id
  name    = local.http_compute_url_map
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_url_map" "https-map" {
  count           = local.ssl ? 1 : 0
  provider        = google
  name            = local.https_compute_url_map
  default_service = google_compute_backend_bucket.compute_backend_bucket[keys(var.backend_bucket)[0]].self_link
  project         = var.project_id
}

# LB Proxy
resource "google_compute_target_http_proxy" "http-redirect" {
  count   = local.redirect_to_https ? 1 : 0
  project = var.project_id
  name    = local.http_target_proxy_name
  url_map = join("", google_compute_url_map.http-redirect.*.self_link)
}

resource "google_compute_target_https_proxy" "https" {
  count            = local.ssl ? 1 : 0
  project          = var.project_id
  provider         = google
  name             = local.https_target_proxy_name
  url_map          = join("", google_compute_url_map.https-map.*.self_link)
  ssl_certificates = concat(google_compute_managed_ssl_certificate.compute_managed_ssl_certificate.*.self_link)
}

# LB Forwarding rule
resource "google_compute_global_forwarding_rule" "http-redirect" {
  count      = local.redirect_to_https ? 1 : 0
  project    = var.project_id
  name       = local.http_forwarding_rule_name
  target     = google_compute_target_http_proxy.http-redirect[0].self_link
  ip_address = google_compute_global_address.compute_global_address[0].address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "https" {
  count    = local.ssl ? 1 : 0
  project  = var.project_id
  provider = google
  name     = local.https_forwarding_rule_name
  #https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts#protocol-specifications
  load_balancing_scheme = var.load_balancing_scheme
  ip_address            = google_compute_global_address.compute_global_address[0].address
  ip_protocol           = var.ip_protocol
  port_range            = var.port_range
  target                = google_compute_target_https_proxy.https[0].self_link
}
