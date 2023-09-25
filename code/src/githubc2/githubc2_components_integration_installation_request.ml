module Primary = struct
  module Account = struct
    type t =
      | Simple_user of Githubc2_components_simple_user.t
      | Enterprise of Githubc2_components_enterprise.t
    [@@deriving show, eq]

    let of_yojson =
      Json_schema.any_of
        (let open CCResult in
         [
           (fun v -> map (fun v -> Simple_user v) (Githubc2_components_simple_user.of_yojson v));
           (fun v -> map (fun v -> Enterprise v) (Githubc2_components_enterprise.of_yojson v));
         ])

    let to_yojson = function
      | Simple_user v -> Githubc2_components_simple_user.to_yojson v
      | Enterprise v -> Githubc2_components_enterprise.to_yojson v
  end

  type t = {
    account : Account.t;
    created_at : string;
    id : int;
    node_id : string option; [@default None]
    requester : Githubc2_components_simple_user.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
