#
# Module: DynamoDB Table Creation
#
locals {
    # <prefix>- or blank
    name_prefix = "%{if var.prefix != ""}${var.prefix}-%{else}%{endif}"
}

#
# Client Table
#
resource "aws_dynamodb_table" "Client" {
    name = "${local.name_prefix}Client"
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 5
    hash_key = "ClientId"
    
    attribute {
        name = "ClientId"
        type = "S"
    }
    attribute {
        name = "JsonString"
        type = "S"
    }

    global_secondary_index {
        name = "JsonString-Index"
        hash_key = "JsonString"
        projection_type = "ALL"        
        read_capacity = 5
        write_capacity = 5
    }
}

#
# ApiResource Table
#
resource "aws_dynamodb_table" "ApiResource" {
    name = "${local.name_prefix}ApiResource"
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 5
    hash_key = "Name"
    
    attribute {
        name = "Name"
        type = "S"
    }
    attribute {
        name = "JsonString"
        type = "S"
    }

    global_secondary_index {
        name = "JsonString-Index"
        hash_key = "JsonString"
        projection_type = "ALL"        
        read_capacity = 5
        write_capacity = 5
    }
}

#
# IdentityResource
#
resource "aws_dynamodb_table" "IdentityResource" {
    name = "${local.name_prefix}IdentityResource"
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 5
    hash_key = "Name"
    
    attribute {
        name = "Name"
        type = "S"
    }
    attribute {
        name = "JsonString"
        type = "S"
    }

    global_secondary_index {
        name = "JsonString-Index"
        hash_key = "JsonString"
        projection_type = "ALL"        
        read_capacity = 5
        write_capacity = 5
    }
}

#
# PersistedGrant Table
# NOTE: this table has TTL enbabled
#
resource "aws_dynamodb_table" "PersistedGrant" {
    name = "${local.name_prefix}PersistedGrant"
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 5
    hash_key = "Key"
    
    attribute {
        name = "Key"
        type = "S"
    }
    attribute {
        name = "ClientId"
        type = "S"
    }
    attribute {
        name = "Subject"
        type = "S"
    }
    attribute {
        name = "Type"
        type = "S"
    }

    global_secondary_index {
        name = "ClientId-Index"
        hash_key = "ClientId"
        projection_type = "ALL"        
        read_capacity = 5
        write_capacity = 5
    }

    global_secondary_index {
        name = "Subject-Index"
        hash_key = "Subject"
        projection_type = "ALL"        
        read_capacity = 5
        write_capacity = 5
    }

    global_secondary_index {
        name = "Type-Index"
        hash_key = "Type"
        projection_type = "ALL"        
        read_capacity = 5
        write_capacity = 5
    }

    ttl {
        attribute_name = "Expiration"
        enabled = true
    }
}
