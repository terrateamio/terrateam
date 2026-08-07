resource "boundary_account" "this" {
  count = length(var.account) == "0" ? "0" : length(var.auth_method)
  auth_method_id = try(
    element(boundary_auth_method.this.*.id, lookup(var.account[count.index], "auth_method_id"))
  )
  type        = lookup(var.account[count.index], "type")
  description = lookup(var.account[count.index], "description")
  login_name  = lookup(var.account[count.index], "login_name")
  name        = lookup(var.account[count.index], "name")
  password    = sensitive(lookup(var.account[count.index], "password"))
}

resource "boundary_account_ldap" "this" {
  count = length(var.account_ldap) == "0" ? "0" : length(var.auth_method)
  auth_method_id = try(
    element(boundary_auth_method.this.*.id, lookup(var.account_ldap[count.index], "auth_method_id"))
  )
  description = lookup(var.account_ldap[count.index], "description")
  login_name  = lookup(var.account_ldap[count.index], "login_name")
  name        = lookup(var.account_ldap[count.index], "name")
}

resource "boundary_account_oidc" "this" {
  count = length(var.account_oidc) == "0" ? "0" : length(var.auth_method)
  auth_method_id = try(
    element(boundary_auth_method.this.*.id, lookup(var.account_oid[count.index], "auth_method_id"))
  )
  description = lookup(var.account_oidc[count.index], "description")
  issuer      = lookup(var.account_oidc[count.index], "issuer")
  name        = lookup(var.account_oidc[count.index], "name")
  subject     = lookup(var.account_oidc[count.index], "subject")
}

resource "boundary_account_password" "this" {
  count = length(var.account_password) == "0" ? "0" : length(var.auth_method)
  auth_method_id = try(
    element(boundary_auth_method.this.*.id, lookup(var.account_password[count.index], "auth_method_id"))
  )
  description = lookup(var.account_password[count.index], "description")
  login_name  = lookup(var.account_password[count.index], "login_name")
  name        = lookup(var.account_password[count.index], "name")
  password    = sensitive(lookup(var.account_password[count.index], "password"))
}

resource "boundary_auth_method" "this" {
  count = length(var.auth_method) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.auth_method[count.index], "scope_id"))
  )
  type        = lookup(var.auth_method[count.index], "type")
  description = lookup(var.auth_method[count.index], "description")
  name        = lookup(var.auth_method[count.index], "name")
}

resource "boundary_auth_method_oidc" "this" {
  count = length(var.auth_method_oidc) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.auth_method_oidc[count.index], "scope_id"))
  )
  account_claim_maps                   = lookup(var.auth_method_oidc[count.index], "account_claim_maps")
  allowed_audiences                    = lookup(var.auth_method_oidc[count.index], "allowed_audiences")
  api_url_prefix                       = lookup(var.auth_method_oidc[count.index], "api_url_prefix")
  callback_url                         = lookup(var.auth_method_oidc[count.index], "callback_url")
  claims_scopes                        = lookup(var.auth_method_oidc[count.index], "claims_scopes")
  client_id                            = lookup(var.auth_method_oidc[count.index], "client_id")
  client_secret                        = sensitive(lookup(var.auth_method_oidc[count.index], "client_secret"))
  client_secret_hmac                   = lookup(var.auth_method_oidc[count.index], "client_secret_hmac")
  description                          = lookup(var.auth_method_oidc[count.index], "description")
  disable_discovered_config_validation = lookup(var.auth_method_oidc[count.index], "disable_discovered_config_validation")
  idp_ca_certs                         = lookup(var.auth_method_oidc[count.index], "idp_ca_certs")
  is_primary_for_scope                 = lookup(var.auth_method_oidc[count.index], "is_primary_for_scope")
  issuer                               = lookup(var.auth_method_oidc[count.index], "issuer")
  max_age                              = lookup(var.auth_method_oidc[count.index], "max_age")
  name                                 = lookup(var.auth_method_oidc[count.index], "name")
  prompts                              = lookup(var.auth_method_oidc[count.index], "prompts")
  signing_algorithms                   = lookup(var.auth_method_oidc[count.index], "signing_algorithms")
  state                                = lookup(var.auth_method_oidc[count.index], "state")
  type                                 = lookup(var.auth_method_oidc[count.index], "type")
}

resource "boundary_auth_method_ldap" "this" {
  count = length(var.auth_method_ldap) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.auth_method_ldap[count.index], "scope_id"))
  )
  account_attribute_maps      = lookup(var.auth_method_ldap[count.index], "account_attribute_maps")
  anon_group_search           = lookup(var.auth_method_ldap[count.index], "anon_group_search")
  bind_dn                     = lookup(var.auth_method_ldap[count.index], "bind_dn")
  bind_password               = sensitive(lookup(var.auth_method_ldap[count.index], "bind_password"))
  bind_password_hmac          = lookup(var.auth_method_ldap[count.index], "bind_password_hmac")
  certificates                = lookup(var.auth_method_ldap[count.index], "certificates")
  client_certificate          = lookup(var.auth_method_ldap[count.index], "client_certificate")
  client_certificate_key      = lookup(var.auth_method_ldap[count.index], "client_certificate_key")
  client_certificate_key_hmac = lookup(var.auth_method_ldap[count.index], "client_certificate_key_hmac")
  dereference_aliases         = lookup(var.auth_method_ldap[count.index], "dereference_aliases")
  description                 = lookup(var.auth_method_ldap[count.index], "description")
  discover_dn                 = lookup(var.auth_method_ldap[count.index], "discover_dn")
  enable_groups               = lookup(var.auth_method_ldap[count.index], "enable_groups")
  group_attr                  = lookup(var.auth_method_ldap[count.index], "group_attr")
  group_dn                    = lookup(var.auth_method_ldap[count.index], "group_dn")
  group_filter                = lookup(var.auth_method_ldap[count.index], "group_filter")
  insecure_tls                = lookup(var.auth_method_ldap[count.index], "insecure_tls")
  is_primary_for_scope        = lookup(var.auth_method_ldap[count.index], "is_primary_for_scope")
  maximum_page_size           = lookup(var.auth_method_ldap[count.index], "maximum_page_size")
  name                        = lookup(var.auth_method_ldap[count.index], "name")
  start_tls                   = lookup(var.auth_method_ldap[count.index], "start_tls")
  state                       = lookup(var.auth_method_ldap[count.index], "state")
  type                        = lookup(var.auth_method_ldap[count.index], "type")
  upn_domain                  = lookup(var.auth_method_ldap[count.index], "upn_domain")
  urls                        = lookup(var.auth_method_ldap[count.index], "urls")
  use_token_groups            = lookup(var.auth_method_ldap[count.index], "use_token_groups")
  user_attr                   = lookup(var.auth_method_ldap[count.index], "user_attr")
  user_dn                     = lookup(var.auth_method_ldap[count.index], "user_dn")
  user_filter                 = lookup(var.auth_method_ldap[count.index], "user_filter")
}

resource "boundary_auth_method_password" "this" {
  count = length(var.auth_method_password) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.auth_method_password[count.index], "scope_id"))
  )
  description           = lookup(var.auth_method_password[count.index], "description")
  min_login_name_length = lookup(var.auth_method_password[count.index], "min_login_name_length")
  min_password_length   = lookup(var.auth_method_password[count.index], "min_password_length")
  name                  = lookup(var.auth_method_password[count.index], "name")
  type                  = lookup(var.auth_method_password[count.index], "type")
}

resource "boundary_credential_json" "this" {
  count = length(var.credential_json) == "0" ? "0" : length(var.credential_store_static)
  credential_store_id = try(
    element(boundary_credential_store_static.this.*.id, lookup(var.credential_json[count.index], "credential_store_id"))
  )
  object      = file(lookup(var.credential_json[count.index], "object"))
  description = lookup(var.credential_json[count.index], "description")
  name        = lookup(var.credential_json[count.index], "name")
}

resource "boundary_credential_library_vault" "this" {
  count = length(var.credential_library_vault) == "0" ? "0" : length(var.credential_store_static)
  credential_store_id = try(
    element(boundary_credential_store_static.this.*.id, lookup(var.credential_library_vault[count.index], "credential_store_id"))
  )
  path                         = lookup(var.credential_library_vault[count.index], "path")
  credential_mapping_overrides = lookup(var.credential_library_vault[count.index], "credential_mapping_overrides")
  credential_type              = lookup(var.credential_library_vault[count.index], "credential_type")
  description                  = lookup(var.credential_library_vault[count.index], "description")
  http_method                  = lookup(var.credential_library_vault[count.index], "http_method")
  http_request_body            = lookup(var.credential_library_vault[count.index], "http_request_body")
  name                         = lookup(var.credential_library_vault[count.index], "name")
}

resource "boundary_credential_library_vault_ssh_certificate" "this" {
  count = length(var.credential_library_vault_ssh_certificate) == "0" ? "0" : length(var.credential_store_static)
  credential_store_id = try(
    element(boundary_credential_store_static.this.*.id, lookup(var.credential_library_vault_ssh_certificate[count.index], "credential_store_id"))
  )
  path             = lookup(var.credential_library_vault_ssh_certificate[count.index], "path")
  username         = lookup(var.credential_library_vault_ssh_certificate[count.index], "username")
  critical_options = lookup(var.credential_library_vault_ssh_certificate[count.index], "critical_options")
  description      = lookup(var.credential_library_vault_ssh_certificate[count.index], "description")
  extensions       = lookup(var.credential_library_vault_ssh_certificate[count.index], "extensions")
  key_bits         = lookup(var.credential_library_vault_ssh_certificate[count.index], "key_bits")
  key_id           = lookup(var.credential_library_vault_ssh_certificate[count.index], "key_id")
  key_type         = lookup(var.credential_library_vault_ssh_certificate[count.index], "key_type")
  name             = lookup(var.credential_library_vault_ssh_certificate[count.index], "name")
  ttl              = lookup(var.credential_library_vault_ssh_certificate[count.index], "ttl")
}

resource "boundary_credential_ssh_private_key" "this" {
  count = length(var.credential_ssh_private_key) == "0" ? "0" : length(var.credential_store_static)
  credential_store_id = try(
    element(boundary_credential_store_static.this.*.id, lookup(var.credential_ssh_private_key[count.index], "credential_store_id"))
  )
  private_key            = file(lookup(var.credential_library_vault_ssh_certificate[count.index], "private_key"))
  username               = lookup(var.credential_library_vault_ssh_certificate[count.index], "username")
  description            = lookup(var.credential_library_vault_ssh_certificate[count.index], "description")
  name                   = lookup(var.credential_library_vault_ssh_certificate[count.index], "name")
  private_key_passphrase = lookup(var.credential_library_vault_ssh_certificate[count.index], "private_key_passphrase")
}

resource "boundary_credential_store_static" "this" {
  count = length(var.credential_store_static) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.credential_store_static[count.index], "scope_id"))
  )
  description = lookup(var.credential_store_static[count.index], "description")
  name        = lookup(var.credential_store_static[count.index], "name")
}

resource "boundary_credential_store_vault" "this" {
  count   = length(var.credential_store_vault) == "0" ? "0" : length(var.scope)
  address = lookup(var.credential_store_vault[count.index], "address")
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.credential_store_vault[count.index], "scope_id"))
  )
  token                  = lookup(var.credential_store_vault[count.index], "token")
  ca_cert                = lookup(var.credential_store_vault[count.index], "ca_cert")
  client_certificate     = lookup(var.credential_store_vault[count.index], "client_certificate")
  client_certificate_key = lookup(var.credential_store_vault[count.index], "client_certificate_key")
  description            = lookup(var.credential_store_vault[count.index], "description")
  name                   = lookup(var.credential_store_vault[count.index], "name")
  namespace              = lookup(var.credential_store_vault[count.index], "namespace")
  tls_server_name        = lookup(var.credential_store_vault[count.index], "tls_server_name")
  tls_skip_verify        = lookup(var.credential_store_vault[count.index], "tls_skip_verify")
  worker_filter          = lookup(var.credential_store_vault[count.index], "worker_filter")
}

resource "boundary_credential_username_password" "this" {
  count = length(var.credential_username_password) == "0" ? "0" : length(var.credential_store_static)
  credential_store_id = try(
    element(boundary_credential_store_static.this.*.id, lookup(var.credential_username_password[count.index], "credential_store_id"))
  )
  password    = sensitive(lookup(var.credential_username_password[count.index], "password"))
  username    = lookup(var.credential_username_password[count.index], "username")
  description = lookup(var.credential_username_password[count.index], "description")
  name        = lookup(var.credential_username_password[count.index], "name")
}

resource "boundary_group" "this" {
  count = length(var.group) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.group[count.index], "scope_id"))
  )
  description = lookup(var.group[count.index], "description")
  member_ids = try(
    element(boundary_user.this.*.id, lookup(var.group[count.index], "member_ids"))
  )
  name = lookup(var.group[count.index], "name")
}

resource "boundary_host" "this" {
  count = length(var.host) == "0" ? "0" : length(var.host_catalog)
  host_catalog_id = try(
    element(boundary_host_catalog.this.*.id, lookup(var.host[count.index], "host_catalog_id"))
  )
  type        = lookup(var.host[count.index], "type")
  address     = lookup(var.host[count.index], "address")
  description = lookup(var.host[count.index], "description")
  name        = lookup(var.host[count.index], "name")
}

resource "boundary_host_catalog" "this" {
  count = length(var.host_catalog) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.host_catalog[count.index], éscope_id))
  )
  type        = lookup(var.host_catalog[count.index], "type")
  description = lookup(var.host_catalog[count.index], "description")
  name        = lookup(var.host_catalog[count.index], "name")
}

resource "boundary_host_catalog_plugin" "this" {
  count = length(var.host_catalog_plugin) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.host_catalog_plugin[count.index], "scope_id"))
  )
  attributes_json                            = jsonencode(lookup(var.host_catalog_plugin[count.index], "attributes_json"))
  description                                = lookup(var.host_catalog_plugin[count.index], "description")
  internal_force_update                      = lookup(var.host_catalog_plugin[count.index], "internal_force_update")
  internal_hmac_used_for_secrets_config_hmac = lookup(var.host_catalog_plugin[count.index], "internal_hmac_used_for_secrets_config_hmac")
  internal_secrets_config_hmac               = lookup(var.host_catalog_plugin[count.index], "internal_secrets_config_hmac")
  name                                       = lookup(var.host_catalog_plugin[count.index], "name")
  plugin_id                                  = lookup(var.host_catalog_plugin[count.index], "plugin_id")
  plugin_name                                = lookup(var.host_catalog_plugin[count.index], "plugin_name")
  secrets_hmac                               = lookup(var.host_catalog_plugin[count.index], "secrets_hmac")
  secrets_json                               = jsonencode(lookup(var.host_catalog_plugin[count.index], "secrets_json"))
}

resource "boundary_host_catalog_static" "this" {
  count = length(var.host_catalog_static) == "0" ? "0" : length(var.scope)
  scope_id = try(
    element(boundary_scope.this.*.id, lookup(var.host_catalog_static[count.index], "scope_id"))
  )
  description = lookup(var.host_catalog_static[count.index], "description")
  name        = lookup(var.host_catalog_static[count.index], "name")
}

resource "boundary_host_set" "this" {
  count = length(var.host_set) == "0" ? "0" : length(var.host_catalog)
  host_catalog_id = try(
    element(boundary_host_catalog.this.*.id, lookup(var.host_set[count.index], "host_catalog_id"))
  )
  type        = lookup(var.host_set[count.index], "type")
  description = lookup(var.host_set[count.index], "description")
  host_ids = try(
    element(boundary_host.this.*.id, lookup(var.host_set[count.index], "host_ids"))
  )
  name = lookup(var.host_set[count.index], "name")
}

resource "boundary_host_set_plugin" "this" {
  count = length(var.host_set_plugin) == "0" ? "0" : length(var.host_catalog)
  host_catalog_id = try(
    element(boundary_host_catalog.this.*.id, lookup(var.host_set_plugin[count.index], "host_catalog_id"))
  )
  attributes_json       = jsonencode(lookup(var.host_set_plugin[count.index], "attributes_json"))
  description           = lookup(var.host_set_plugin[count.index], "description")
  name                  = lookup(var.host_set_plugin[count.index], "name")
  preferred_endpoints   = lookup(var.host_set_plugin[count.index], "preferred_endpoints")
  sync_interval_seconds = lookup(var.host_set_plugin[count.index], "sync_interval_seconds")
  type                  = lookup(var.host_set_plugin[count.index], "type")
}

resource "boundary_host_set_static" "this" {
  count = length(var.host_set_static) == "0" ? "0" : length(var.host_catalog)
  host_catalog_id = try(
    element(boundary_host_catalog.this.*.id, lookup(var.host_set_static[count.index], "host_catalog_id"))
  )
  description = lookup(var.host_set_static[count.index], "description")
  host_ids = try(
    element(boundary_host.this.*.id, lookup(var.host_set_static[count.index], "host_ids"))
  )
  name = lookup(var.host_set_static[count.index], "name")
  type = lookup(var.host_set_static[count.index], "type")
}

resource "boundary_host_static" "this" {
  count = length(var.host_static) == "0" ? "0" : length(var.host_catalog)
  host_catalog_id = try(
    element(boundary_host_catalog.this.*.id, lookup(var.host_static[count.index], "host_catalog_id"))
  )
  address     = lookup(var.host_static[count.index], "address")
  description = lookup(var.host_static[count.index], "description")
  name        = lookup(var.host_static[count.index], "name")
  type        = lookup(var.host_static[count.index], "type")
}

resource "boundary_managed_group" "this" {
  count          = length(var.managed_group) == "0" ? "0" : length(var.auth_method)
  auth_method_id = try(
    element(boundary_auth_method.this.*.id, lookup(var.managed_group[count.index], "auth_method_id"))
  )
  filter         = lookup(var.managed_group[count.index], "filter")
  description    = lookup(var.managed_group[count.index], "description")
  name           = lookup(var.managed_group[count.index], "name")
}

resource "boundary_managed_group_ldap" "this" {
  count          = length(var.managed_group_ldap) == "0" ? "0" : length(var.auth_method)
  auth_method_id = try(
    element(boundary_auth_method.this.*.id, lookup(var.managed_group_ldap[count.index], "auth_method_id"))
  )
  group_names    = lookup(var.managed_group_ldap[count.index], "group_names")
  description    = lookup(var.managed_group_ldap[count.index], "description")
  name           = lookup(var.managed_group_ldap[count.index], "name")
}

resource "boundary_role" "this" {
  count          = length(var.role) == "0" ? "0" : length(var.scope)
  scope_id       = try(
    element(boundary_scope.this.*.id, lookup(var.role[count.index], "scope_id"))
  )
  description    = lookup(var.role[count.index], "description")
  grant_strings  = lookup(var.role[count.index], "grant_strings")
  name           = lookup(var.role[count.index], "name")
  principal_ids  = try(
    element(boundary_user.this.*.id, lookup(var.role[count.index], "principal_ids"))
  )
}

resource "boundary_scope" "this" {
  count                    = length(var.scope) == "0" ? "0" : length(var.scope)
  scope_id                 = try(
    element(boundary_scope.this.*.id, lookup(var.scope[count.index], "scope_id"))
  )
  auto_create_admin_role   = lookup(var.scope[count.index], "auto_create_admin_role")
  auto_create_default_role = lookup(var.scope[count.index], "auto_create_default_role")
  description              = lookup(var.scope[count.index], "description")
  global_scope             = lookup(var.scope[count.index], "global_scope")
  name                     = lookup(var.scope[count.index], "name")
}

resource "boundary_storage_bucket" "this" {
  count           = length(var.storage_bucket) == "0" ? "0" : length(var.scope)
  bucket_name     = lookup(var.storage_bucket[count.index], "bucket_name")
  scope_id        = try(
    element(boundary_scope.this.*.id, lookup(var.storage_bucket[count.index], "scope_id"))
  )
  secrets_json    = jsonencode(lookup(var.storage_bucket[count.index], "secrets_json"))
  worker_filter   = lookup(var.storage_bucket[count.index], "worker_filter")
  attributes_json = jsonencode(lookup(var.storage_bucket[count.index], "attributes_json"))
  bucket_prefix   = lookup(var.storage_bucket[count.index], "bucket_prefix")
  description     = lookup(var.storage_bucket[count.index], "description")
  name            = lookup(var.storage_bucket[count.index], "name")
  plugin_id       = lookup(var.storage_bucket[count.index], "plugin_id")
  plugin_name     = lookup(var.storage_bucket[count.index], "plugin_name")
}

resource "boundary_target" "this" {
  count                                      = length(var.target) == "0" ? "0" : length(var.scope)
  scope_id                                   = try(
    element(boundary_scope.this.*.id, lookup(var.target[count.index], "scope_id"))
  )
  type                                       = lookup(var.target[count.index], "type")
  address                                    = lookup(var.target[count.index], "address")
  brokered_credential_source_ids             = lookup(var.target[count.index], "brokered_credential_source_ids")
  default_client_port                        = lookup(var.target[count.index], "default_client_port")
  default_port                               = lookup(var.target[count.index], "default_port")
  description                                = lookup(var.target[count.index], "description")
  egress_worker_filter                       = lookup(var.target[count.index], "egress_worker_filter")
  enable_session_recording                   = lookup(var.target[count.index], "enable_session_recording")
  host_source_ids                            = try(
    element(boundary_host_set.this.*.id, lookup(var.target[count.index], "host_source_ids"))
  )
  ingress_worker_filter                      = lookup(var.target[count.index], "ingress_worker_filter")
  injected_application_credential_source_ids = try(
    element(boundary_credential_library_vault.this.*.id, lookup(var.target[count.index], "injected_application_credential_source_ids"))
  )
  name                                       = lookup(var.target[count.index], "name")
  session_connection_limit                   = lookup(var.target[count.index], "session_connection_limit")
  session_max_seconds                        = lookup(var.target[count.index], "session_max_seconds")
  storage_bucket_id                          = try(
    element(boundary_storage_bucket.this.*.id, lookup(var.target[count.index], "storage_bucket_id"))
  )
}

resource "boundary_user" "this" {
  count       = length(var.user) == "0" ? "0" : length(var.scope)
  scope_id    = try(
    element(boundary_scope.this.*.id, lookup(var.user[count.index], "scope_id"))
  )
  account_ids = try(
    element(boundary_account_password.this.*.id, lookup(var.user[count.index], "account_ids"))
  )
  description = lookup(var.user[count.index], "description")
  name        = lookup(var.user[count.index], "name")
}

resource "boundary_worker" "this" {
  count                       = length(var.worker)
  description                 = lookup(var.worker[count.index], "description")
  name                        = lookup(var.worker[count.index], "name")
  scope_id                    = try(
    element(boundary_scope.this.*.id, lookup(var.host_catalog_static[count.index], "scope_id"))
  )
  worker_generated_auth_token = lookup(var.worker[count.index], "worker_generated_auth_token")
}