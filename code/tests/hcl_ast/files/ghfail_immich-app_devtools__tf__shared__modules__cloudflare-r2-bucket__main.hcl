data "cloudflare_api_token_permission_groups" "all" {
  provider = cloudflare.api_keys
}

resource "cloudflare_r2_bucket" "bucket" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
  location   = var.location
}

resource "cloudflare_api_token" "bucket_api_token" {
  name     = "r2_token_${var.bucket_name}"
  provider = cloudflare.api_keys

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.r2["Workers R2 Storage Bucket Item Read"],
      data.cloudflare_api_token_permission_groups.all.r2["Workers R2 Storage Bucket Item Write"]
    ]
    resources = {
      "com.cloudflare.edge.r2.bucket.${var.cloudflare_account_id}_default_${var.bucket_name}" = "*"
    }
  }

  dynamic "condition" {
    for_each = length(var.allowed_cidrs) > 0 ? [1] : []
    content {
      request_ip {
        in = var.allowed_cidrs
      }
    }
  }
}

resource "onepassword_item" "bucket_credentials" {
  vault    = var.onepassword_vault_id
  title    = var.item_name
  category = "secure_note"

  section {
    label = "Cloudflare R2 Bucket"

    field {
      label = "bucket_name"
      type  = "STRING"
      value = cloudflare_r2_bucket.bucket.name
    }

    field {
      label = "endpoint"
      type  = "STRING"
      value = "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com"
    }

    field {
      label = "access_key_id"
      type  = "CONCEALED"
      value = cloudflare_api_token.bucket_api_token.id
    }

    field {
      label = "secret_access_key"
      type  = "CONCEALED"
      value = sha256(cloudflare_api_token.bucket_api_token.value)
    }
  }
}
