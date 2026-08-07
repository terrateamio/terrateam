resource "example" "test" {
  account = provider::aws::arn_parse(var.arn).account_id
  decoded = provider::http::decode_body(data.http.example.response_body, "application/json")
}
