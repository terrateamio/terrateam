module Primary = struct
  module Details = struct
    type t =
      | Secret_scanning_location_commit of Githubc2_components_secret_scanning_location_commit.t
    [@@deriving show]

    let of_yojson =
      Json_schema.one_of
        (let open CCResult in
        [
          (fun v ->
            map
              (fun v -> Secret_scanning_location_commit v)
              (Githubc2_components_secret_scanning_location_commit.of_yojson v));
        ])

    let to_yojson = function
      | Secret_scanning_location_commit v ->
          Githubc2_components_secret_scanning_location_commit.to_yojson v
  end

  module Type = struct
    let t_of_yojson = function
      | `String "commit" -> Ok "commit"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    details : Details.t;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
