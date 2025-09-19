module V0 = struct
  let t_of_yojson = function
    | `String "access-token-refresh" -> Ok "access-token-refresh"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V1 = struct
  let t_of_yojson = function
    | `String "access-token-create" -> Ok "access-token-create"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V2 = struct
  let t_of_yojson = function
    | `String "kv-store-read" -> Ok "kv-store-read"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V3 = struct
  let t_of_yojson = function
    | `String "kv-store-write" -> Ok "kv-store-write"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module V4 = struct
  module Primary = struct
    module Name = struct
      let t_of_yojson = function
        | `String "vcs" -> Ok "vcs"
        | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

      type t = (string[@of_yojson t_of_yojson])
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    type t = {
      name : Name.t option; [@default None]
      vcs : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

type t =
  | V0 of V0.t
  | V1 of V1.t
  | V2 of V2.t
  | V3 of V3.t
  | V4 of V4.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
     [
       (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
       (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
       (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
       (fun v -> map (fun v -> V3 v) (V3.of_yojson v));
       (fun v -> map (fun v -> V4 v) (V4.of_yojson v));
     ])

let to_yojson = function
  | V0 v -> V0.to_yojson v
  | V1 v -> V1.to_yojson v
  | V2 v -> V2.to_yojson v
  | V3 v -> V3.to_yojson v
  | V4 v -> V4.to_yojson v
