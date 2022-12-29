module Primary = struct
  module Alt_domain = struct
    module Primary = struct
      type t = {
        caa_error : string option; [@default None]
        dns_resolves : bool option; [@default None]
        enforces_https : bool option; [@default None]
        has_cname_record : bool option; [@default None]
        has_mx_records_present : bool option; [@default None]
        host : string option; [@default None]
        https_error : string option; [@default None]
        is_a_record : bool option; [@default None]
        is_apex_domain : bool option; [@default None]
        is_cloudflare_ip : bool option; [@default None]
        is_cname_to_fastly : bool option; [@default None]
        is_cname_to_github_user_domain : bool option; [@default None]
        is_cname_to_pages_dot_github_dot_com : bool option; [@default None]
        is_fastly_ip : bool option; [@default None]
        is_https_eligible : bool option; [@default None]
        is_non_github_pages_ip_present : bool option; [@default None]
        is_old_ip_address : bool option; [@default None]
        is_pages_domain : bool option; [@default None]
        is_pointed_to_github_pages_ip : bool option; [@default None]
        is_proxied : bool option; [@default None]
        is_served_by_pages : bool option; [@default None]
        is_valid : bool option; [@default None]
        is_valid_domain : bool option; [@default None]
        nameservers : string option; [@default None]
        reason : string option; [@default None]
        responds_to_https : bool option; [@default None]
        should_be_a_record : bool option; [@default None]
        uri : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Domain = struct
    module Primary = struct
      type t = {
        caa_error : string option; [@default None]
        dns_resolves : bool option; [@default None]
        enforces_https : bool option; [@default None]
        has_cname_record : bool option; [@default None]
        has_mx_records_present : bool option; [@default None]
        host : string option; [@default None]
        https_error : string option; [@default None]
        is_a_record : bool option; [@default None]
        is_apex_domain : bool option; [@default None]
        is_cloudflare_ip : bool option; [@default None]
        is_cname_to_fastly : bool option; [@default None]
        is_cname_to_github_user_domain : bool option; [@default None]
        is_cname_to_pages_dot_github_dot_com : bool option; [@default None]
        is_fastly_ip : bool option; [@default None]
        is_https_eligible : bool option; [@default None]
        is_non_github_pages_ip_present : bool option; [@default None]
        is_old_ip_address : bool option; [@default None]
        is_pages_domain : bool option; [@default None]
        is_pointed_to_github_pages_ip : bool option; [@default None]
        is_proxied : bool option; [@default None]
        is_served_by_pages : bool option; [@default None]
        is_valid : bool option; [@default None]
        is_valid_domain : bool option; [@default None]
        nameservers : string option; [@default None]
        reason : string option; [@default None]
        responds_to_https : bool option; [@default None]
        should_be_a_record : bool option; [@default None]
        uri : string option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  type t = {
    alt_domain : Alt_domain.t option; [@default None]
    domain : Domain.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
