module V0 = struct
  type t = string [@@deriving yojson { strict = false; meta = true }, show]
end

module V1 = struct
  type t = float [@@deriving yojson { strict = false; meta = true }, show]
end

type t =
  | V0 of V0.t
  | V1 of V1.t
[@@deriving show]

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