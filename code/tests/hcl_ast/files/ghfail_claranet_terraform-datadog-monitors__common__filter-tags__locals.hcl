locals {
  including_default_list = compact(
    concat(
      split(
        local.filter_tags_separator,
        format(
          "dd_monitoring:enabled${local.filter_tags_separator}dd_%s:enabled${local.filter_tags_separator}env:%s",
          var.resource,
          var.environment,
        ),
      ),
      compact(var.extra_tags),
    ),
  )
  including_custom_list = compact(
    concat(split("${local.filter_tags_separator}", var.filter_tags_custom), compact(var.extra_tags)),
  )

  excluding_list = compact(
    split(
      local.filter_tags_separator,
      var.filter_tags_use_defaults == "true" ? join(local.filter_tags_separator, compact(var.extra_tags_excluded)) : join(
        local.filter_tags_separator,
        concat(
          split(local.filter_tags_separator, var.filter_tags_custom_excluded),
          compact(var.extra_tags_excluded),
        ),
      ),
    ),
  )

  std_including_string = replace("${replace(local.including_string, "${var.filter_tags_separator}", "${local.filter_tags_separator}")}", "/ +/", " ")
  std_excluding_string = replace("${replace(local.excluding_string, "${var.filter_tags_separator}", "${local.filter_tags_separator}")}", "/ +/", " ")

  event_including_string = replace("${replace(local.including_string, "${var.filter_tags_separator}", " ")}", "/ +/", " ")
  event_excluding_string = replace("${replace(local.excluding_string, "${var.filter_tags_separator}", " -")}", "/ +/", " ")

  including_string = var.filter_tags_use_defaults == "true" ? join(local.filter_tags_separator, local.including_default_list) : join(local.filter_tags_separator, local.including_custom_list)
  excluding_string = join(local.filter_tags_separator, local.excluding_list)

  filter_tags_not_operator = var.filter_tags_separator == "AND" ? "NOT " : "!"
  filter_tags_separator    = var.filter_tags_separator == "AND" ? " AND " : ","

  query_alert = join(
    local.filter_tags_separator,
    compact(
      concat(
        formatlist("${local.filter_tags_not_operator}%s", local.excluding_list),
        [local.std_including_string],
      ),
    ),
  )

  service_check           = ".over(\"${replace(local.std_including_string, "${local.filter_tags_separator}", "\"${local.filter_tags_separator}\"")}\")${local.std_excluding_string == "" ? "" : ".exclude(\"${replace(local.std_excluding_string, "${local.filter_tags_separator}", "\"${local.filter_tags_separator}\"")}\")"}"
  service_check_sanitized = replace(replace(replace(local.service_check, "\"(", "(\""), ")\"", "\")"), " OR ", "\" OR \"")
}

