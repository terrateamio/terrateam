module Type = struct
  type t = Installation_type_github of Terrat_api_components_installation_type_github.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v ->
           map
             (fun v -> Installation_type_github v)
             (Terrat_api_components_installation_type_github.of_yojson v));
       ])

  let to_yojson = function
    | Installation_type_github v -> Terrat_api_components_installation_type_github.to_yojson v
end

type t = {
  id : string;
  name : string;
  type_ : Type.t; [@key "type"]
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
