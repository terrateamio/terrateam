module Primary = struct
  module Payload = struct
    module V0 = struct
      include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
    end

    module V1 = struct
      type t = string [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t =
      | V0 of V0.t
      | V1 of V1.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
           (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
         ])

    let to_yojson = function
      | V0 v -> V0.to_yojson v
      | V1 v -> V1.to_yojson v
  end

  type t = {
    created_at : string;
    creator : Githubc2_components_nullable_simple_user.t option;
    description : string option;
    environment : string;
    id : int;
    node_id : string;
    original_environment : string option; [@default None]
    payload : Payload.t;
    performed_via_github_app : Githubc2_components_nullable_integration.t option; [@default None]
    production_environment : bool option; [@default None]
    ref_ : string; [@key "ref"]
    repository_url : string;
    sha : string;
    statuses_url : string;
    task : string;
    transient_environment : bool option; [@default None]
    updated_at : string;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
