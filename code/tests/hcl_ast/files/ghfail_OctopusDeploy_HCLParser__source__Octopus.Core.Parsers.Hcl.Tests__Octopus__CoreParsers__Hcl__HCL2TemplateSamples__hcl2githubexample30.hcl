data "azurerm_key_vault" "vault" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault_certificate" "kv_cert_import" {
  count        = var.key_vault_cert_import_filepath == "" ? 0 : 1
  name         = var.key_vault_cert_name
  key_vault_id = data.azurerm_key_vault.vault.id

  certificate {
    contents = filebase64(var.key_vault_cert_import_filepath)
    password = ""
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = var.key_vault_content_type
    }
  }
}

resource "azurerm_key_vault_certificate" "kv_cert_self_assign" {
  count        = var.key_vault_cert_import_filepath == "" ? 1 : 0
  name         = var.key_vault_cert_name
  key_vault_id = data.azurerm_key_vault.vault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = var.key_vault_cert_days_before_expiry
      }
    }

    secret_properties {
      content_type = var.key_vault_content_type
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = var.key_vault_cert_alt_names
      }

      subject            = "CN=${var.key_vault_cert_subject}"
      validity_in_months = var.key_vault_cert_validity_months
    }
  }
}

data "external" "public_cert" {
  depends_on = [
    azurerm_key_vault_certificate.kv_cert_self_assign,
    azurerm_key_vault_certificate.kv_cert_import,
  ]

  program = ["az", "keyvault", "certificate", "show", "--name", var.key_vault_cert_name, "--vault-name", var.keyvault_name, "-o", "json", "--query", "{cer:cer}"]
}

data "external" "private_pfx" {
  depends_on = [
    azurerm_key_vault_certificate.kv_cert_self_assign,
    azurerm_key_vault_certificate.kv_cert_import,
  ]

  program = ["az", "keyvault", "secret", "show", "--name", var.key_vault_cert_name, "--vault-name", var.keyvault_name, "-o", "json", "--query", "{value:value}"]
}