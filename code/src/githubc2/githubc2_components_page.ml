module Primary = struct
  module Build_type = struct
    let t_of_yojson = function
      | `String "legacy" -> Ok "legacy"
      | `String "workflow" -> Ok "workflow"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Protected_domain_state = struct
    let t_of_yojson = function
      | `String "pending" -> Ok "pending"
      | `String "verified" -> Ok "verified"
      | `String "unverified" -> Ok "unverified"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "built" -> Ok "built"
      | `String "building" -> Ok "building"
      | `String "errored" -> Ok "errored"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    build_type : Build_type.t option; [@default None]
    cname : string option;
    custom_404 : bool; [@default false]
    html_url : string option; [@default None]
    https_certificate : Githubc2_components_pages_https_certificate.t option; [@default None]
    https_enforced : bool option; [@default None]
    pending_domain_unverified_at : string option; [@default None]
    protected_domain_state : Protected_domain_state.t option; [@default None]
    public : bool;
    source : Githubc2_components_pages_source_hash.t option; [@default None]
    status : Status_.t option;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
