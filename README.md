# terraform-gcp-modules-cloud-storage-bucket

## Overview

This Terraform configuration sets up a below listed GCP Services:

1.  **Website Bucket**: The configuration provisions a Google Cloud Storage bucket using the  `google_storage_bucket`  resource. It sets up the bucket with specified settings such as name, location, storage class, versioning, website configuration, CORS settings, encryption, labels, and logging.  
    
2.  **Bucket ACLs**: The configuration sets the default object ACLs for the website bucket using the  `google_storage_default_object_acl`  resource. ACLs can be specified in the  `var.website_acls`  variable.  
    
3.  **Access Logs Bucket**: The configuration creates a separate bucket to store access logs for the website using the  `google_storage_bucket`  resource. It sets up the bucket with specified settings such as name, location, storage class, encryption, and lifecycle rules.  
    
4.  **Compute Backend Bucket**: The configuration creates a compute backend bucket using the  `google_compute_backend_bucket`  resource. The backend bucket is associated with the website bucket and can be used for serving static content through a CDN. It sets up the backend bucket with specified settings such as name, bucket name, description, CDN settings, compression mode, and custom response headers.  
    
5.  **External IP**: The configuration reserves an external IP address using the  `google_compute_global_address`  resource. The IP address is used for the load balancer.  
    
6.  **GCP Managed DNS Zone**: The configuration retrieves the managed DNS zone using the  `google_dns_managed_zone`  data source. This is used to add the IP address to the DNS records when `gcp_managed_domain` variable is true.
    
7.  **GCP DNS Records**: The configuration creates DNS records using the  `google_dns_record_set`  resource. It adds A or CNAME records pointing to the IP address of the load balancer  when `gcp_managed_domain` variable is true.
    
8.  **HTTPS Certificate**: The configuration creates an HTTPS certificate using the  `google_compute_managed_ssl_certificate`  resource. This certificate is used for SSL/TLS termination.  
    
9.  **HTTPS URL Map**: The configuration creates an HTTPS URL map using the  `google_compute_url_map`  resource. It associates the URL map with the backend bucket and SSL certificate.  
    
10.  **HTTPS Target Proxy**: The configuration creates an HTTPS target proxy using the  `google_compute_target_https_proxy`  resource. It associates the target proxy with the URL map and SSL certificate.  
    
11.  **HTTPS Forwarding Rule**: The configuration creates an HTTPS forwarding rule using the  `google_compute_global_forwarding_rule`  resource. It associates the forwarding rule with the target proxy and external IP.  
    
12.  **HTTP URL Map and Target Proxy**: The configuration creates an HTTP URL map and target proxy using the  `google_compute_url_map`  and  `google_compute_target_http_proxy`  resources, respectively. These are used for HTTP redirect.  
    
13.  **HTTP Forwarding Rule**: The configuration creates an HTTP forwarding rule using the  `google_compute_global_forwarding_rule`  resource. It associates the forwarding rule with the target proxy and external IP.

14.  **AWS Managed DNS Zone**: The configuration retrieves the managed DNS zone using the  `aws_route53_zone`  data source. This is used to add the IP address to the DNS records when `gcp_managed_domain` variable is false.

15.  **AWS DNS Records**: The configuration creates DNS records using the  `aws_route53_record`  resource. It adds A or CNAME records pointing to the IP address of the load balancer  when `use_google_dns` variable is false.

16.  **AWS Route53 Custom Domain Management**: When `use_aws_route53` is set to true, the configuration creates additional Route53 A records for custom domains managed in AWS, including both the main domain and www subdomain.   

## Usage

`Bucket`:

```hcl
module "bucket" {
  source     = "nurdsoft/storage-bucket/google"
  project_id = "zeus-404008"
  labels = {
    cloud       = "gcp"
    component   = "bucket"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name = "simple-bucket"
}
```

`Bucket with Public Access`:

```hcl
module "bucket" {
  source     = "nurdsoft/storage-bucket/google"
  project_id = "zeus-404008"
  labels = {
    cloud       = "gcp"
    component   = "bucket"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name = "simple-bucket"
  enable_public_access = true
}
```

`Static Site with Default Domain`:

```hcl
module "bucket" {
  source     = "nurdsoft/storage-bucket/google"
  project_id = "zeus-404008"
  labels = {
    cloud       = "gcp"
    component   = "static-site"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name                      = "static-site"
  create_access_logs_bucket = true
  create_load_balancer      = true
  enable_public_access      = true
  enable_secure_connection  = true

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
```

`Static Site with Custom Domain`:

```hcl
module "bucket" {
  source     = "nurdsoft/storage-bucket/google"
  project_id = "zeus-404008"
  labels = {
    cloud       = "gcp"
    component   = "static-site"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name                      = "static-site"
  domain_name               = "pacenthink.co"
  create_access_logs_bucket = true
  create_load_balancer      = true
  enable_public_access      = true
  enable_secure_connection  = true

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
```

`Static Site with AWS Route53 Domain Management`:

```hcl
module "bucket" {
  source     = "nurdsoft/storage-bucket/google"
  project_id = "your-gcp-project-id"
  labels = {
    cloud       = "gcp"
    component   = "static-site"
    customer    = "nurdsoft"
    environment = "dev"
  }
  name                      = "dev"
  domain_name               = "nurdsoft.com"
  create_access_logs_bucket = true
  create_load_balancer      = true
  enable_public_access      = true
  enable_secure_connection  = true
  use_aws_route53          = true  # Enable AWS Route53 record creation

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
```

## Assumptions

The project assumes the following:

- A basic understanding of [Git](https://git-scm.com/).
- Git version `>= 2.33.0`.
- An existing GCP IAM user or role with access to create/update/delete resources defined in [main.tf](https://github.com/nurdsoft/terraform-google-storage-bucket/blob/main/main.tf).
- An existing AWS IAM user or role with access to create/update/delete resources defined in [main.tf](https://github.com/nurdsoft/terraform-google-storage-bucket/blob/main/main.tf).
- [GCloud CLI](https://cloud.google.com/sdk/docs/install)  `>= 465.0.0`
- A basic understanding of [Terraform](https://www.terraform.io/).
- Terraform version `>= 1.6.0`
- (Optional - for local testing) A basic understanding of [Make](https://www.gnu.org/software/make/manual/make.html#Introduction).
  - Make version `>= GNU Make 3.81`.
  - **Important Note**: This project includes a [Makefile](https://github.com/nurdsoft/terraform-google-storage-bucket/blob/main/Makefile) to speed up local development in Terraform. The `make` targets act as a wrapper around Terraform commands. As such, `make` has only been tested/verified on **Linux/Mac OS**. Though, it is possible to [install make using Chocolatey](https://community.chocolatey.org/packages/make), we **do not** guarantee this approach as it has not been tested/verified. You may use the commands in the [Makefile](https://github.com/nurdsoft/terraform-google-storage-bucket/blob/main/Makefile) as a guide to run each Terraform command locally on Windows.

## Test

**Important Note**: This project includes a [Makefile](https://github.com/nurdsoft/terraform-google-storage-bucket/blob/main/Makefile) to speed up local development in Terraform. The `make` targets act as a wrapper around Terraform commands. As such, `make` has only been tested/verified on **Linux/Mac OS**. Though, it is possible to [install make using Chocolatey](https://community.chocolatey.org/packages/make), we **do not** guarantee this approach as it has not been tested/verified. You may use the commands in the [Makefile](https://github.com/nurdsoft/terraform-google-storage-bucket/blob/main/Makefile) as a guide to run each Terraform command locally on Windows.

```sh
export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
export AWS_DEFAULT_REGION=<AWS_DEFAULT_REGION>
gcloud init # https://cloud.google.com/docs/authentication/gcloud
gcloud auth
make plan
make apply
make destroy
```

## Contributions

Contributions are always welcome. As such, this project uses the `main` branch as the source of truth to track changes.

**Step 1**. Clone this project.

```sh
# Using Git
$ git clone git@github.com:nurdsoft/terraform-google-storage-bucket.git

# Using HTTPS
$ git clone https://github.com/nurdsoft/terraform-google-storage-bucket.git
```

**Step 2**. Checkout a feature branch: `git checkout -b feature/abc`.

**Step 3**. Validate the change/s locally by executing the steps defined under [Test](#test).

**Step 4**. If testing is successful, commit and push the new change/s to the remote.

```sh
$ git add file1 file2 ...

$ git commit -m "Adding some change"

$ git push --set-upstream origin feature/abc
```

**Step 5**. Once pushed, create a [PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) and assign it to a member for review.

- **Important Note**: It can be helpful to attach the `terraform plan` output in the PR.

**Step 6**. A team member reviews/approves/merges the change/s.

**Step 7**. Once merged, deploy the required changes as needed.

**Step 8**. Once deployed, verify that the changes have been deployed.

- If possible, please add a `plan` output using the feature branch so the member reviewing the MR has better visibility in the changes.

## Requirements

| Name | Version |
|------|---------|
| aws | 5.44.0 |
| google | 5.16.0 |
| random | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| aws | 5.44.0 |
| google | 5.16.0 |
| google-beta | n/a |
| random | >= 2.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| access\_log\_prefix | The object prefix for log objects. If it's not provided, it is set to the value of var.website\_domain\_name with dots are replaced with dashes, e.g. 'site-acme-com'. | `string` | `""` | no |
| access\_logs\_expiration\_time\_in\_days | How many days to keep access logs around for before deleting them. | `number` | `30` | no |
| access\_logs\_kms\_key\_name | A Cloud KMS key that will be used to encrypt objects inserted into the access logs bucket. If empty, the contents will not be encrypted. You must pay attention to whether the crypto key is available in the location that this bucket is created in. | `string` | `""` | no |
| backend\_bucket | Map backend indices to list of backend maps. | <pre>map(object({<br>    description                     = optional(string)<br>    enable_cdn                      = optional(bool)<br>    custom_response_headers         = optional(list(string))<br>    timeout_sec                     = optional(number)<br>    connection_draining_timeout_sec = optional(number)<br>    session_affinity                = optional(string)<br>    affinity_cookie_ttl_sec         = optional(number)<br>    locality_lb_policy              = optional(string)<br>    compression_mode                = optional(string)<br>    edge_security_policy            = optional(string, null)<br>    cdn_policy = optional(object({<br>      cache_mode                   = optional(string)<br>      signed_url_cache_max_age_sec = optional(string)<br>      default_ttl                  = optional(number)<br>      max_ttl                      = optional(number)<br>      client_ttl                   = optional(number)<br>      negative_caching             = optional(bool)<br>      negative_caching_policy = optional(object({<br>        code = optional(number)<br>        ttl  = optional(number)<br>      }))<br>      serve_while_stale = optional(number)<br>      cache_key_policy = optional(object({<br>        query_string_whitelist = optional(list(string))<br>        include_http_headers   = optional(list(string))<br>      }))<br>      bypass_cache_on_request_headers = optional(object({<br>        header_name = optional(bool)<br>      }))<br>    }))<br>  }))</pre> | `{}` | no |
| bucket\_kms\_key\_name | A Cloud KMS key that will be used to encrypt objects inserted into the website bucket. If empty, the contents will not be encrypted. You must pay attention to whether the crypto key is available in the location that this bucket is created in. | `string` | `""` | no |
| bucket\_labels | A map of custom labels to apply to the resources. The key is the label name and the value is the label value. | `map(string)` | `{}` | no |
| bucket\_location | Location of the bucket that will store the static website. Once a bucket has been created, its location can't be changed. See https://cloud.google.com/storage/docs/bucket-locations | `string` | `"US"` | no |
| bucket\_policy\_only | Enables Bucket Policy Only access to a bucket. | `bool` | `false` | no |
| bucket\_storage\_class | Storage class of the bucket that will store the static website | `string` | `"MULTI_REGIONAL"` | no |
| cors | Configuration of CORS for bucket with structure as defined in https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket#cors. | `any` | `[]` | no |
| create\_access\_logs\_bucket | If provided true, access\_logs bucket will be created for static hosting bucket. | `bool` | `false` | no |
| create\_load\_balancer | Wether to Create Application Loadbalancer or not | `bool` | `false` | no |
| custom\_placement\_config | Configuration of the bucket's custom location in a dual-region bucket setup. If the bucket is designated a single or multi-region, the variable are null. | <pre>object({<br>    data_locations = list(string)<br>  })</pre> | `null` | no |
| default\_domain\_name | Default root domain for application url mapping | `string` | `"nurdsoft.co"` | no |
| dns\_record\_ttl | The TTL (time-to-live) of the record in seconds. This is required for non-alias<br>records. | `number` | `60` | no |
| dns\_record\_type | The record type. Valid values are A, AAAA, CAA, CNAME, DS, MX, NAPTR, NS, PTR, <br>SOA, SPF, SRV and TXT. | `string` | `"A"` | no |
| dns\_zone\_private | Whether the Route53 zone is private. | `bool` | `false` | no |
| domain\_name | The name of the website and the Cloud Storage bucket to create (e.g. static.foo.com). | `string` | `""` | no |
| enable\_autoclass | While set to true, autoclass is enabled for this bucket. | `bool` | `false` | no |
| enable\_cors | Set to true if you want to enable CORS headers | `bool` | `false` | no |
| enable\_secure\_connection | Set to `true` to enable SSL support at domain endpoint (https://) | `bool` | `false` | no |
| enable\_versioning | Set to true to enable versioning. This means the website bucket will retain all old versions of all files. This is useful for backup purposes (e.g. you can rollback to an older version), but it may mean your bucket uses more storage. | `bool` | `true` | no |
| encryption | A Cloud KMS key that will be used to encrypt objects inserted into this bucket | <pre>object({<br>    default_kms_key_name = string<br>  })</pre> | `null` | no |
| force\_destroy | When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects. | `bool` | `false` | no |
| force\_destroy\_access\_logs\_bucket | If set to true, this will force the delete of the access logs bucket when you run terraform destroy, even if there is still content in it. This is only meant for testing and should not be used in production. | `bool` | `false` | no |
| force\_destroy\_bucket | If set to true, this will force the delete of the website bucket when you run terraform destroy, even if there is still content in it. This is only meant for testing and should not be used in production. | `bool` | `false` | no |
| ip\_protocol | The IP protocol to which this rule applies. For protocol forwarding, valid options are TCP, UDP, ESP, AH, SCTP, ICMP and L3\_DEFAULT | `string` | `"TCP"` | no |
| labels | A set of key/value label pairs to assign to the bucket. | `map(string)` | `null` | no |
| lifecycle\_rules | The bucket's Lifecycle Rules configuration. | <pre>list(object({<br>    action    = any<br>    condition = any<br>  }))</pre> | `[]` | no |
| load\_balancing\_scheme | Specifies the forwarding rule type.Possible values are: EXTERNAL, EXTERNAL\_MANAGED, INTERNAL\_MANAGED, INTERNAL\_SELF\_MANAGED. | `string` | `"EXTERNAL"` | no |
| location | The location of the bucket. | `string` | `"US"` | no |
| log\_bucket | The bucket that will receive log objects. | `string` | `null` | no |
| log\_bucket\_custom\_placement\_config | Configuration of the bucket's custom location in a dual-region bucket setup. If the bucket is designated a single or multi-region, the variable are null. | <pre>object({<br>    data_locations = list(string)<br>  })</pre> | `null` | no |
| log\_bucket\_lifecycle\_rules | The bucket's Lifecycle Rules configuration. | <pre>list(object({<br>    action    = any<br>    condition = any<br>  }))</pre> | <pre>[<br>  {<br>    "action": {<br>      "type": "Delete"<br>    },<br>    "condition": {<br>      "age": 90<br>    }<br>  }<br>]</pre> | no |
| log\_object\_prefix | The object prefix for log objects. If it's not provided, by default GCS sets this to this bucket's name | `string` | `null` | no |
| name | The name of the website and the Cloud Storage bucket to create (e.g. static.foo.com). | `string` | n/a | yes |
| port\_range | Port Range for Load Balancer | `string` | `"443"` | no |
| project\_id | The ID to give the project. If not provided, the `name` will be used. | `string` | `""` | no |
| public\_access\_prevention | Prevents public access to a bucket. Acceptable values are inherited or enforced. If inherited, the bucket uses public access prevention, only if the bucket is subject to the public access prevention organization policy constraint. | `string` | `"inherited"` | no |
| random\_certificate\_suffix | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| redirect\_to\_https | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| retention\_policy | Configuration of the bucket's data retention policy for how long objects in the bucket should be retained. | <pre>object({<br>    is_locked        = bool<br>    retention_period = number<br>  })</pre> | `null` | no |
| storage\_class | The Storage Class of the new bucket. | `string` | `null` | no |
| use\_google\_dns | Set to true only if using Google Cloud DNS instead of Route53 | `bool` | `false` | no |
| use\_aws\_route53 | Set to true if domain is already managed in AWS Route53 and you want to create Route53 records | `bool` | `false` | no |
| website\_default\_map | Map of website values. Supported attributes: main\_page\_suffix, not\_found\_page | `map(any)` | <pre>{<br>  "main_page_suffix": "index.html"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| google\_compute\_global\_ip\_address | Reserved External IP address |