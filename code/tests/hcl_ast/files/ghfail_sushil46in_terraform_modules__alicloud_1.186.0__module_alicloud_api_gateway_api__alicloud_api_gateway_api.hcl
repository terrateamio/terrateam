/*This terraform file has been generated programmatically using terraform-generator.*/
/*All the commented lines, if any, are optional. Remove comment characters, if required, before using.*/
/*Refer https://github.com/sushil46in/terraform_modules.git for more details.*/

resource "alicloud_api_gateway_api" "resname" {
  auth_type = var.api_gateway_api_auth_type
  description = var.api_gateway_api_description
  group_id = var.api_gateway_api_group_id
  name = var.api_gateway_api_name
  service_type = var.api_gateway_api_service_type
  #stage_names = var.api_gateway_api_stage_names

  constant_parameters {
    #description = var.api_gateway_api_constant_parameters_description
    in = var.api_gateway_api_constant_parameters_in
    name = var.api_gateway_api_constant_parameters_name
    value = var.api_gateway_api_constant_parameters_value
  }

  fc_service_config {
    #arn_role = var.api_gateway_api_fc_service_config_arn_role
    function_name = var.api_gateway_api_fc_service_config_function_name
    region = var.api_gateway_api_fc_service_config_region
    service_name = var.api_gateway_api_fc_service_config_service_name
    timeout = var.api_gateway_api_fc_service_config_timeout
  }

  http_service_config {
    address = var.api_gateway_api_http_service_config_address
    #aone_name = var.api_gateway_api_http_service_config_aone_name
    method = var.api_gateway_api_http_service_config_method
    path = var.api_gateway_api_http_service_config_path
    timeout = var.api_gateway_api_http_service_config_timeout
  }

  http_vpc_service_config {
    #aone_name = var.api_gateway_api_http_vpc_service_config_aone_name
    method = var.api_gateway_api_http_vpc_service_config_method
    name = var.api_gateway_api_http_vpc_service_config_name
    path = var.api_gateway_api_http_vpc_service_config_path
    timeout = var.api_gateway_api_http_vpc_service_config_timeout
  }

  mock_service_config {
    #aone_name = var.api_gateway_api_mock_service_config_aone_name
    result = var.api_gateway_api_mock_service_config_result
  }

  request_config {
    #body_format = var.api_gateway_api_request_config_body_format
    method = var.api_gateway_api_request_config_method
    mode = var.api_gateway_api_request_config_mode
    path = var.api_gateway_api_request_config_path
    protocol = var.api_gateway_api_request_config_protocol
  }

  request_parameters {
    #default_value = var.api_gateway_api_request_parameters_default_value
    #description = var.api_gateway_api_request_parameters_description
    in = var.api_gateway_api_request_parameters_in
    in_service = var.api_gateway_api_request_parameters_in_service
    name = var.api_gateway_api_request_parameters_name
    name_service = var.api_gateway_api_request_parameters_name_service
    required = var.api_gateway_api_request_parameters_required
    type = var.api_gateway_api_request_parameters_type
  }

  system_parameters {
    in = var.api_gateway_api_system_parameters_in
    name = var.api_gateway_api_system_parameters_name
    name_service = var.api_gateway_api_system_parameters_name_service
  }

}

