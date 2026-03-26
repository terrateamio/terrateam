module Primary = struct
  module Build_type = struct
    let t_of_yojson = function
      | `String "legacy" -> Ok `Legacy
      | `String "workflow" -> Ok `Workflow
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Legacy -> `String "legacy"
      | `Workflow -> `String "workflow"

    type t =
      ([ `Legacy
       | `Workflow
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Protected_domain_state = struct
    let t_of_yojson = function
      | `String "pending" -> Ok `Pending
      | `String "unverified" -> Ok `Unverified
      | `String "verified" -> Ok `Verified
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Pending -> `String "pending"
      | `Unverified -> `String "unverified"
      | `Verified -> `String "verified"

    type t =
      ([ `Pending
       | `Unverified
       | `Verified
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "building" -> Ok `Building
      | `String "built" -> Ok `Built
      | `String "errored" -> Ok `Errored
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    let t_to_yojson = function
      | `Building -> `String "building"
      | `Built -> `String "built"
      | `Errored -> `String "errored"

    type t =
      ([ `Building
       | `Built
       | `Errored
       ]
      [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    build_type : Build_type.t option; [@default None]
    cname : string option; [@default None]
    custom_404 : bool; [@default false]
    html_url : string option; [@default None]
    https_certificate : Githubc2_components_pages_https_certificate.t option; [@default None]
    https_enforced : bool option; [@default None]
    pending_domain_unverified_at : string option; [@default None]
    protected_domain_state : Protected_domain_state.t option; [@default None]
    public : bool;
    source : Githubc2_components_pages_source_hash.t option; [@default None]
    status : Status_.t option; [@default None]
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
