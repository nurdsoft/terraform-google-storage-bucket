# ------------------------------------------------------------------------------
# Storage Bucket
# ------------------------------------------------------------------------------

variable "customer" {
  description = "Customer name used for resource naming (e.g., 'acme', 'nurdsoft')"
  type        = string
}

variable "environment" {
  description = "Environment name used for resource naming (e.g., 'dev', 'staging', 'prod')"
  type        = string
}
variable "project_id" {
  description = "The ID to give the project. If not provided, the `name` will be used."
  type        = string
  default     = ""
}

variable "bucket_location" {
  description = "Location of the bucket that will store the static website. Once a bucket has been created, its location can't be changed. See https://cloud.google.com/storage/docs/bucket-locations"
  type        = string
  default     = "US"
}

variable "bucket_storage_class" {
  description = "Storage class of the bucket that will store the static website"
  type        = string
  default     = "MULTI_REGIONAL"
}

variable "enable_versioning" {
  description = "Set to true to enable versioning. This means the website bucket will retain all old versions of all files. This is useful for backup purposes (e.g. you can rollback to an older version), but it may mean your bucket uses more storage."
  type        = bool
  default     = true
}

variable "enable_cors" {
  description = "Set to true if you want to enable CORS headers"
  type        = bool
  default     = false
}


variable "force_destroy_bucket" {
  description = "If set to true, this will force the delete of the website bucket when you run terraform destroy, even if there is still content in it. This is only meant for testing and should not be used in production."
  type        = bool
  default     = false
}

variable "force_destroy_access_logs_bucket" {
  description = "If set to true, this will force the delete of the access logs bucket when you run terraform destroy, even if there is still content in it. This is only meant for testing and should not be used in production."
  type        = bool
  default     = false
}

variable "access_logs_expiration_time_in_days" {
  description = "How many days to keep access logs around for before deleting them."
  type        = number
  default     = 30
}

variable "create_access_logs_bucket" {
  description = "If provided true, access_logs bucket will be created for static hosting bucket."
  type        = bool
  default     = false
}

variable "access_log_prefix" {
  description = "The object prefix for log objects. If it's not provided, it is set to the value of var.website_domain_name with dots are replaced with dashes, e.g. 'site-acme-com'."
  type        = string
  default     = ""
}

variable "bucket_kms_key_name" {
  description = "A Cloud KMS key that will be used to encrypt objects inserted into the website bucket. If empty, the contents will not be encrypted. You must pay attention to whether the crypto key is available in the location that this bucket is created in."
  type        = string
  default     = ""
}

variable "access_logs_kms_key_name" {
  description = "A Cloud KMS key that will be used to encrypt objects inserted into the access logs bucket. If empty, the contents will not be encrypted. You must pay attention to whether the crypto key is available in the location that this bucket is created in."
  type        = string
  default     = ""
}

variable "bucket_labels" {
  description = "A map of custom labels to apply to the resources. The key is the label name and the value is the label value."
  type        = map(string)
  default     = {}
}

variable "enable_autoclass" {
  description = "While set to true, autoclass is enabled for this bucket."
  type        = bool
  default     = false
}

variable "location" {
  description = "The location of the bucket."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "The Storage Class of the new bucket."
  type        = string
  default     = null
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the bucket."
  type        = map(string)
  default     = null
}

variable "bucket_policy_only" {
  description = "Enables Bucket Policy Only access to a bucket."
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects."
  type        = bool
  default     = false
}

variable "retention_policy" {
  description = "Configuration of the bucket's data retention policy for how long objects in the bucket should be retained."
  type = object({
    is_locked        = bool
    retention_period = number
  })
  default = null
}

variable "custom_placement_config" {
  description = "Configuration of the bucket's custom location in a dual-region bucket setup. If the bucket is designated a single or multi-region, the variable are null."
  type = object({
    data_locations = list(string)
  })
  default = null
}

variable "log_bucket_custom_placement_config" {
  description = "Configuration of the bucket's custom location in a dual-region bucket setup. If the bucket is designated a single or multi-region, the variable are null."
  type = object({
    data_locations = list(string)
  })
  default = null
}

variable "cors" {
  description = "Configuration of CORS for bucket with structure as defined in https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#cors."
  type        = any
  default     = []
}

variable "encryption" {
  description = "A Cloud KMS key that will be used to encrypt objects inserted into this bucket"
  type = object({
    default_kms_key_name = string
  })
  default = null
}

variable "lifecycle_rules" {
  description = "The bucket's Lifecycle Rules configuration."
  type = list(object({
    action    = any
    condition = any
  }))
  default = []
}

variable "log_bucket_lifecycle_rules" {
  description = "The bucket's Lifecycle Rules configuration."
  type = list(object({
    action    = any
    condition = any
  }))
  default = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 90
      }
    }
  ]
}

variable "log_bucket" {
  description = "The bucket that will receive log objects."
  type        = string
  default     = null
}

variable "log_object_prefix" {
  description = "The object prefix for log objects. If it's not provided, by default GCS sets this to this bucket's name"
  type        = string
  default     = null
}

variable "website_default_map" {
  type = map(any)
  default = {
    main_page_suffix = "index.html"
  }
  description = "Map of website values. Supported attributes: main_page_suffix, not_found_page"
}

variable "public_access_prevention" {
  description = "Prevents public access to a bucket. Acceptable values are inherited or enforced. If inherited, the bucket uses public access prevention, only if the bucket is subject to the public access prevention organization policy constraint."
  type        = string
  default     = "inherited"
}
# ------------------------------------------------------------------------------
# LoadBalancer & DNS
# ------------------------------------------------------------------------------
variable "create_load_balancer" {
  description = "Wether to Create Application Loadbalancer or not "
  type        = bool
  default     = false
}

variable "enable_secure_connection" {
  description = "Set to `true` to enable SSL support at domain endpoint (https://) "
  type        = bool
  default     = false
}

variable "redirect_to_https" {
  description = "Set to `false` to disable HTTP port 80 forward"
  type        = bool
  default     = true
}

variable "ip_protocol" {
  description = " The IP protocol to which this rule applies. For protocol forwarding, valid options are TCP, UDP, ESP, AH, SCTP, ICMP and L3_DEFAULT"
  type        = string
  default     = "TCP"
}

variable "load_balancing_scheme" {
  description = "Specifies the forwarding rule type.Possible values are: EXTERNAL, EXTERNAL_MANAGED, INTERNAL_MANAGED, INTERNAL_SELF_MANAGED."
  type        = string
  default     = "EXTERNAL"
}

variable "port_range" {
  description = "Port Range for Load Balancer"
  type        = string
  default     = "443"
}

variable "backend_bucket" {
  description = "Map backend indices to list of backend maps."
  default     = {}
  type = map(object({
    description                     = optional(string)
    enable_cdn                      = optional(bool)
    custom_response_headers         = optional(list(string))
    timeout_sec                     = optional(number)
    connection_draining_timeout_sec = optional(number)
    session_affinity                = optional(string)
    affinity_cookie_ttl_sec         = optional(number)
    locality_lb_policy              = optional(string)
    compression_mode                = optional(string)
    edge_security_policy            = optional(string, null)
    cdn_policy = optional(object({
      cache_mode                   = optional(string)
      signed_url_cache_max_age_sec = optional(string)
      default_ttl                  = optional(number)
      max_ttl                      = optional(number)
      client_ttl                   = optional(number)
      negative_caching             = optional(bool)
      negative_caching_policy = optional(object({
        code = optional(number)
        ttl  = optional(number)
      }))
      serve_while_stale = optional(number)
      cache_key_policy = optional(object({
        query_string_whitelist = optional(list(string))
        include_http_headers   = optional(list(string))
      }))
      bypass_cache_on_request_headers = optional(object({
        header_name = optional(bool)
      }))
    }))
  }))
}

variable "dns_record_ttl" {
  description = <<DESC
The TTL (time-to-live) of the record in seconds. This is required for non-alias
records.
DESC
  type        = number
  default     = 60
}

variable "dns_record_type" {
  description = <<DESC
The record type. Valid values are A, AAAA, CAA, CNAME, DS, MX, NAPTR, NS, PTR,
SOA, SPF, SRV and TXT.
DESC
  type        = string
  default     = "A"
}

variable "dns_zone_private" {
  description = "Whether the Route53 zone is private."
  type        = bool
  default     = false
}

variable "default_domain_name" {
  description = "Default root domain for application url mapping"
  type        = string
  default     = "nurdsoft.co"
}

variable "random_certificate_suffix" {
  description = "Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert."
  type        = bool
  default     = false
}

variable "name" {
  description = "The name of the website and the Cloud Storage bucket to create (e.g. static.foo.com)."
  type        = string
}

variable "domain_name" {
  description = "The name of the website and the Cloud Storage bucket to create (e.g. static.foo.com)."
  type        = string
  default     = ""
}

variable "use_google_dns" {
  type        = bool
  default     = false
  description = "Set to true only if using Google Cloud DNS instead of Route53"
}

variable "use_aws_route53" {
  type        = bool
  default     = false
  description = "Set to true if domain is already managed in AWS Route53 and you want to create Route53 records"
}

variable "enable_public_access" {
  description = "Set to true to make the bucket publicly accessible. This will create IAM bindings for allUsers with storage.objects.get permission."
  type        = bool
  default     = false
}
