module Additional = struct
  module V0 = struct
    type t = string option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module V1 = struct
    type t = float option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module V2 = struct
    type t = bool option [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t =
    | V0 of V0.t
    | V1 of V1.t
    | V2 of V2.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.any_of
      (let open CCResult in
      [
        (fun v -> map (fun v -> V0 v) (V0.of_yojson v));
        (fun v -> map (fun v -> V1 v) (V1.of_yojson v));
        (fun v -> map (fun v -> V2 v) (V2.of_yojson v));
      ])

  let to_yojson = function
    | V0 v -> V0.to_yojson v
    | V1 v -> V1.to_yojson v
    | V2 v -> V2.to_yojson v
end

include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
