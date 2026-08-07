data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  region = var.region == "" ? data.aws_region.this.name : var.region
  bucket = var.bucket == "" ? "prep-registration-${random_pet.this.id}" : var.bucket
  nid = var.network_name == "testnet" ? 80 : var.network_name == "mainnet" ? 1 : ""
  url = var.network_name == "testnet" ? "https://zicon.net.solidwallet.io" : "https://ctz.solidwallet.io/api/v3"

  ip = var.ip == null ? aws_eip.this.*.public_ip[0] : var.ip

  tags = merge(var.tags, {"Name" = "${var.network_name}-ip"})
}

resource "aws_eip" "this" {
  count = var.ip == null ? 1 : 0
  vpc = true
  tags = local.tags

  lifecycle {
    prevent_destroy = false
  }
}

resource "random_pet" "this" {
  length = 2
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket
  acl    = "public-read"

  website {
    index_document = "index.html"
  }

  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${local.bucket}/*",
      "Principal": "*"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_object" "logo_256" {
  count = var.logo_256 == "" ? 0 : 1
  bucket = aws_s3_bucket.bucket.bucket
  key = basename(var.logo_256)
  source = var.logo_256
}

resource "aws_s3_bucket_object" "logo_1024" {
  count = var.logo_1024 == "" ? 0 : 1
  bucket = aws_s3_bucket.bucket.bucket
  key = basename(var.logo_1024)
  source = var.logo_1024
}

resource "aws_s3_bucket_object" "logo_svg" {
  count = var.logo_svg == "" ? 0 : 1
  bucket = aws_s3_bucket.bucket.bucket
  key = basename(var.logo_svg)
  source = var.logo_svg
}
data "template_file" "details" {
  template = file("${path.module}/details.json")
  vars = {
    logo_256 = "http://${aws_s3_bucket.bucket.website_endpoint}/${basename(var.logo_256)}"
    logo_1024 = "http://${aws_s3_bucket.bucket.website_endpoint}/${basename(var.logo_1024)}"
    logo_svg = "http://${aws_s3_bucket.bucket.website_endpoint}/${basename(var.logo_svg)}"

    steemit = var.steemit
    twitter = var.twitter
    youtube = var.youtube
    facebook = var.facebook
    github = var.github
    reddit = var.reddit
    keybase = var.keybase
    telegram = var.telegram
    wechat = var.wechat

    country = var.organization_country
    region = var.organization_city
    server_type = var.server_type

    ip = local.ip
  }
}

data "template_file" "registration" {
  template = file("${path.module}/registerPRep.json")
  vars = {
    name = var.organization_name
    country = var.organization_country
    city = var.organization_city
    email = var.organization_email
    website = var.organization_website

    details_endpoint = "http://${aws_s3_bucket.bucket.website_endpoint}/details.json"

    ip = local.ip
  }
  depends_on = [aws_s3_bucket.bucket]
}

resource "aws_s3_bucket_object" "details" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "details.json"
  content = data.template_file.details.rendered
}

//resource "null_resource" "registration" {
//  provisioner "local-exec" {
//    command = <<-EOF
//echo "Y" | preptools registerPRep \
//--url ${local.url} \
//--nid ${local.nid} \
//%{if var.keystore_path != ""}--keystore ${var.keystore_path}%{ endif } \
//%{if var.keystore_password != ""}--password "${var.keystore_password}"%{ endif } \
//%{if var.organization_name != ""}--name "${var.organization_name}"%{ endif } \
//%{if var.organization_country != ""}--country "${var.organization_country}"%{ endif } \
//%{if var.organization_city != ""}--city "${var.organization_city}"%{ endif } \
//%{if var.organization_email != ""}--email "${var.organization_email}"%{ endif } \
//%{if var.organization_website != ""}--website "${var.organization_website}"%{ endif } \
//--details http://${aws_s3_bucket.bucket.website_endpoint}/details.json \
//--p2p-endpoint "${local.ip}:7100"
//EOF
//  }
//
//  triggers = {
//    build_number = timestamp()
//  }
//
//  depends_on = [aws_s3_bucket_object.details]
//}

//// TTD build logic to handle setPRep
//resource "null_resource" "update_registration" {
//  provisioner "local-exec" {
//    command = <<-EOF
//echo "Y" | preptools setPRep \
//--url ${local.url} \
//--nid ${local.nid} \
//%{if var.keystore_path != ""}--keystore ${var.keystore_path}%{ endif } \
//%{if var.keystore_password != ""}--password "${var.keystore_password}"%{ endif } \
//%{if var.organization_name != ""}--name "${var.organization_name}"%{ endif } \
//%{if var.organization_country != ""}--country "${var.organization_country}"%{ endif } \
//%{if var.organization_city != ""}--city "${var.organization_city}"%{ endif } \
//%{if var.organization_email != ""}--email "${var.organization_email}"%{ endif } \
//%{if var.organization_website != ""}--website "${var.organization_website}"%{ endif } \
//--details ${aws_s3_bucket.bucket.bucket_regional_domain_name}/details.json \
//--p2p-endpoint "${local.ip}:7100"
//EOF
//  }
//
//  triggers = {
//    build_number = timestamp()
//  }
//}
