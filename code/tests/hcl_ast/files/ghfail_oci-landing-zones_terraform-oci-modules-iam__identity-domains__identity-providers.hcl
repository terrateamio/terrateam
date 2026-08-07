# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
data "oci_identity_domain" "idp_domain" {
  for_each  = (var.identity_domain_identity_providers_configuration != null) ? (var.identity_domain_identity_providers_configuration["identity_providers"] != null ? var.identity_domain_identity_providers_configuration["identity_providers"] : {}) : {}
  domain_id = each.value.identity_domain_id != null ? each.value.identity_domain_id : var.identity_domain_identity_providers_configuration.default_identity_domain_id
}

data "http" "saml_metadata" {
  for_each = (var.identity_domain_identity_providers_configuration != null) ? (var.identity_domain_identity_providers_configuration["identity_providers"] != null ? var.identity_domain_identity_providers_configuration["identity_providers"] : {}) : {}
  url      = contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_id, "None")) ? join("", [oci_identity_domain.these[each.value.identity_domain_id].url, local.metadata_uri]) : (contains(keys(oci_identity_domain.these), coalesce(var.identity_domain_identity_providers_configuration.default_identity_domain_id, "None")) ? join("", [oci_identity_domain.these[var.identity_domain_identity_providers_configuration.default_identity_domain_id].url, local.metadata_uri]) : join("", [data.oci_identity_domain.idp_domain[each.key].url, local.metadata_uri]))
}

data "oci_identity_domain" "identity_provider_domain" {
  for_each  = local.target_idps
  domain_id = each.value
}

data "http" "idp_signing_cert" {
  for_each = local.target_idps
  # url = join("",[data.oci_identity_domain.identity_provider_domain[each.key].url,local.sign_cert_uri])
  url = join("", contains(keys(oci_identity_domain.these), coalesce(each.value, "None")) ? [oci_identity_domain.these[each.value].url] : [data.oci_identity_domain.identity_provider_domain[each.key].url], [local.sign_cert_uri])
  depends_on = [
    oci_identity_domains_setting.cert_public_access_setting
  ]
}

data "oci_identity_domains_rule" "default_idp_rule" {
  for_each = (var.identity_domain_identity_providers_configuration != null) ? var.identity_domain_identity_providers_configuration.identity_providers : {}

  idcs_endpoint = contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_id, "None")) ? oci_identity_domain.these[each.value.identity_domain_id].url : (contains(keys(oci_identity_domain.these), coalesce(var.identity_domain_identity_providers_configuration.default_identity_domain_id, "None")) ? oci_identity_domain.these[var.identity_domain_identity_providers_configuration.default_identity_domain_id].url : data.oci_identity_domain.idp_domain[each.key].url)
  rule_id       = "DefaultIDPRule"

  attributes = "return"
  depends_on = [
    oci_identity_domain.these
  ]
}

locals {
  nameid_formats       = ["saml-emailaddress", "saml-x509", "saml-kerberos", "saml-persistent", "saml-transient", "saml-unspecified", "saml-windowsnamequalifier", "saml-none"]
  user_mapping_methods = ["NameIDToUserAttribute", "AssertionAttributeToUserAttribute", "CorrelationPolicyRule"]
  hash_algorithms      = ["SHA-256", "SHA-1"]
  binding_values       = ["Redirect", "Post"]
  idp_parameter_list   = ["idp_issuer_uri", "sso_service_url", "sso_service_binding", "idp_signing_certificate", "idp_logout_request_url", "idp_logout_response_url"]
  metadata_uri         = "/fed/v1/metadata"
  target_idps = { for k, v in var.identity_domain_identity_providers_configuration != null ? var.identity_domain_identity_providers_configuration.identity_providers : {} : k => v.identity_domain_idp_id
    if v.identity_domain_idp_id != null
  }
  current_saml_idps = { for k, v in var.identity_domain_identity_providers_configuration != null ? var.identity_domain_identity_providers_configuration.identity_providers : {} : k => [for ret in data.oci_identity_domains_rule.default_idp_rule[k].return : ret.value if ret.name == "SamlIDPs"]
    if v.add_to_default_idp_policy == true
  }

}


resource "oci_identity_domains_identity_provider" "these" {
  for_each = var.identity_domain_identity_providers_configuration != null ? var.identity_domain_identity_providers_configuration.identity_providers : {}
  lifecycle {
    # ## Check 1: Valid Name ID format.
    # precondition {
    #   condition = each.value.name_id_format != null ? contains(local.nameid_formats, each.value.name_id_format) : true
    #   error_message = "VALIDATION FAILURE in identity provider \"${each.key}\": invalid value for \"name_id_format\" attribute. Valid values are ${join(",",local.nameid_formats)}."
    # }
    ## Check 2: Valid User Mapping method.
    precondition {
      condition     = each.value.user_mapping_method != null ? contains(local.user_mapping_methods, each.value.user_mapping_method) : true
      error_message = "VALIDATION FAILURE in identity provider \"${each.key}\": invalid value for \"user_mapping_method\" attribute. Valid values are ${join(",", local.user_mapping_methods)}."
    }
    ## Check 3: Valid Signature Hash Algorithm.
    precondition {
      condition     = each.value.signature_hash_algorithm != null ? contains(local.hash_algorithms, each.value.signature_hash_algorithm) : true
      error_message = "VALIDATION FAILURE in identity provider \"${each.key}\": invalid value for \"signature_hash_algorithm\" attribute. Valid values are ${join(",", local.hash_algorithms)}."
    }
    ## Check 4: Valid SSO binding values.
    precondition {
      condition     = each.value.sso_service_binding != null ? contains(local.binding_values, each.value.sso_service_binding) : true
      error_message = "VALIDATION FAILURE in identity provider \"${each.key}\": invalid value for \"sso_service_binding\" attribute. Valid values are ${join(",", local.binding_values)}."
    }
    ## Check 5: Valid Logout binding values.
    precondition {
      condition     = each.value.idp_logout_binding != null ? contains(local.binding_values, each.value.idp_logout_binding) : true
      error_message = "VALIDATION FAILURE in identity provider \"${each.key}\": invalid value for \"idp_logout_binding\" attribute. Valid values are ${join(",", local.binding_values)}."
    }
    ## Check 6: Validate IDP parameters when not using idp metadata file
    precondition {
      condition     = (each.value.idp_metadata_file == null && each.value.identity_domain_idp_id == null) ? ((each.value.idp_issuer_uri != null && each.value.sso_service_url != null && each.value.idp_signing_certificate != null && each.value.idp_logout_request_url != null && each.value.idp_logout_response_url != null && each.value.sso_service_binding != null) ? true : false) : true
      error_message = "VALIDATION FAILURE in identity provider \"${each.key}\": when not using \"idp_metadata_file\" attribute, at least the following parameters should be provided: ${join(",", local.idp_parameter_list)}"
    }
  }

  idcs_endpoint = contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_id, "None")) ? oci_identity_domain.these[each.value.identity_domain_id].url : (contains(keys(oci_identity_domain.these), coalesce(var.identity_domain_identity_providers_configuration.default_identity_domain_id, "None")) ? oci_identity_domain.these[var.identity_domain_identity_providers_configuration.default_identity_domain_id].url : data.oci_identity_domain.idp_domain[each.key].url)

  partner_name                 = each.value.name
  enabled                      = each.value.enabled
  schemas                      = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityProvider"]
  description                  = each.value.description
  icon_url                     = each.value.icon_file != null ? file(each.value.icon_file) : null
  name_id_format               = coalesce(each.value.name_id_format, "saml-emailaddress")
  user_mapping_method          = coalesce(each.value.user_mapping_method, "NameIDToUserAttribute")
  user_mapping_store_attribute = coalesce(each.value.user_mapping_store_attribute, "username")

  metadata = each.value.idp_metadata_file != null ? file(each.value.idp_metadata_file) : null

  #partner_provider_id                 = each.value.idp_metadata_file != null ? null : each.value.idp_issuer_uri
  partner_provider_id = each.value.idp_metadata_file != null ? null : each.value.identity_domain_idp_id == null ? each.value.idp_issuer_uri : contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_idp_id, "None")) ? "${oci_identity_domain.these[each.value.identity_domain_idp_id].url}/fed" : "${data.oci_identity_domain.identity_provider_domain[each.key].url}/fed"
  #idp_sso_url                         = each.value.idp_metadata_file != null ? null : each.value.sso_service_url
  idp_sso_url           = each.value.idp_metadata_file != null ? null : each.value.identity_domain_idp_id == null ? each.value.sso_service_url : contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_idp_id, "None")) ? "${oci_identity_domain.these[each.value.identity_domain_idp_id].url}/fed/v1/idp/sso" : "${data.oci_identity_domain.identity_provider_domain[each.key].url}/fed/v1/idp/sso"
  authn_request_binding = each.value.idp_metadata_file != null ? null : each.value.sso_service_binding
  #signing_certificate                 = each.value.idp_metadata_file != null ? null : each.value.idp_signing_certificate 
  signing_certificate    = each.value.idp_metadata_file != null ? null : each.value.identity_domain_idp_id == null ? each.value.idp_signing_certificate : jsondecode(data.http.idp_signing_cert[each.key].response_body).keys[0].x5c[0]
  encryption_certificate = each.value.idp_metadata_file != null ? null : each.value.idp_encryption_certificate
  logout_enabled         = each.value.idp_metadata_file != null ? null : each.value.enable_global_logout
  #logout_request_url                  = each.value.idp_metadata_file != null ? null : each.value.idp_logout_request_url
  logout_request_url = each.value.idp_metadata_file != null ? null : each.value.identity_domain_idp_id == null ? each.value.idp_logout_request_url : contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_idp_id, "None")) ? "${oci_identity_domain.these[each.value.identity_domain_idp_id].url}/fed/v1/idp/slo" : "${data.oci_identity_domain.identity_provider_domain[each.key].url}/fed/v1/idp/slo"
  #logout_response_url                 = each.value.idp_metadata_file != null ? null : each.value.idp_logout_response_url
  logout_response_url = each.value.idp_metadata_file != null ? null : each.value.identity_domain_idp_id == null ? each.value.idp_logout_response_url : contains(keys(oci_identity_domain.these), coalesce(each.value.identity_domain_idp_id, "None")) ? "${oci_identity_domain.these[each.value.identity_domain_idp_id].url}/fed/v1/idp/slo" : "${data.oci_identity_domain.identity_provider_domain[each.key].url}/fed/v1/idp/slo"
  logout_binding      = each.value.idp_metadata_file != null ? null : each.value.idp_logout_binding

  signature_hash_algorithm          = each.value.signature_hash_algorithm
  include_signing_cert_in_signature = each.value.send_signing_certificate
  shown_on_login_page               = each.value.add_to_default_idp_policy
  #OCI Tags not supported

  depends_on = [
    oci_identity_domains_setting.cert_public_access_setting
  ]

  provisioner "local-exec" {
    #command = "[ ${each.value.add_to_default_idp_policy} = false ] && (exit 0) || oci identity-domains rule patch --schemas '[\"urn:ietf:params:scim:api:messages:2.0:PatchOp\"]' --endpoint ${oci_identity_domains_identity_provider.these[each.key].idcs_endpoint} --rule-id \"DefaultIDPRule\" --operations '[{\"op\": \"add\",\"path\": \"return\",\"value\": [{\"name\":\"SamlIDPs\",\"value\":\"[${local.current_saml_idps[each.key]!=[]?trim(local.current_saml_idps[each.key][0],"[]"):"\"\""},\\\"${oci_identity_domains_identity_provider.these[each.key].id}\\\"]\"}]}]'"
    #command = "[ ${each.value.add_to_default_idp_policy} = false ] && (exit 0) || oci identity-domains rule patch --schemas '[\"urn:ietf:params:scim:api:messages:2.0:PatchOp\"]' --endpoint ${oci_identity_domains_identity_provider.these[each.key].idcs_endpoint} --rule-id \"DefaultIDPRule\" --operations '[{\"op\": \"add\",\"path\": \"return\",\"value\": [{\"name\":\"SamlIDPs\",\"value\":\"[${local.current_saml_idps[each.key]!=["[]"]?join(",",concat(["\\\"${trim(local.current_saml_idps[each.key][0],"[]\"")}\\\""],["\\\"${oci_identity_domains_identity_provider.these[each.key].id}\\\""])):"\\\"${oci_identity_domains_identity_provider.these[each.key].id}\\\""}]\"}]}]'"
    command = "[ ${each.value.add_to_default_idp_policy} = false ] && (exit 0) || oci identity-domains rule patch --schemas '[\"urn:ietf:params:scim:api:messages:2.0:PatchOp\"]' --endpoint ${oci_identity_domains_identity_provider.these[each.key].idcs_endpoint} --rule-id \"DefaultIDPRule\" --operations '[{\"op\": \"add\",\"path\": \"return\",\"value\": [{\"name\":\"SamlIDPs\",\"value\":\"[${each.value.add_to_default_idp_policy == true ? (local.current_saml_idps != null && local.current_saml_idps[each.key] != [] ? join(",", concat(["\\\"${trim(local.current_saml_idps[each.key][0], "[]\"")}\\\""], ["\\\"${oci_identity_domains_identity_provider.these[each.key].id}\\\""])) : "\\\"${oci_identity_domains_identity_provider.these[each.key].id}\\\"") : "none"}]\"}]}]'"


    on_failure = fail
  }
}