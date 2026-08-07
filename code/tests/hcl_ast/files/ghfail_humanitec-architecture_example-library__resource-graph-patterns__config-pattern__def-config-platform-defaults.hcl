resource "humanitec_resource_definition" "config-pattern-example-config-platform-defaults" {
  driver_type = "humanitec/template"
  id          = "config-pattern-example-config-platform-defaults"
  name        = "config-pattern-example-config-platform-defaults"
  type        = "config"
  driver_inputs = {
    values_string = jsonencode({
      "templates" = {
        "init"    = <<END_OF_TEXT
defaults:
  # These are values defined by the platform team to be used by the terraform module
  prefix: ""
  region: eu-central-1
  name: {{ "$${context.res.id}" | splitList "." | last }}-$${context.app.id}-$${context.org.id}
  tags:
    example: config-pattern-example
    env: $${context.env.id}
END_OF_TEXT
        "outputs" = <<END_OF_TEXT
{{- $overrides := .driver.values.overrides }}
# Loop through all the default keys - this way we don't introduce additional keys from
# the developer overrides.
{{- range $key, $val := .init.defaults }}

  # Don't allow overrides of some keys
  {{- if (list "region" "tags") | has $key }}

{{ $key }}: {{ $val | toRawJson }}

  {{- else }}

{{ $key }}: {{ $overrides | dig $key $val | toRawJson }}

  {{- end}}

{{- end }}

# Generate some additional keys
bucket_name: {{ $overrides.prefix | default .init.defaults.prefix }}{{ $overrides.name | default .init.defaults.name }}
END_OF_TEXT
      }
      "overrides" = "$${resources['config.developer-overrides'].values}"
    })
  }
}

resource "humanitec_resource_definition_criteria" "config-pattern-example-config-platform-defaults_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.config-pattern-example-config-platform-defaults.id
  app_id                 = "example-config-pattern"
}
