module String_map = CCMap.Make (CCString)

module Additional_properties = struct
  module type Primary = sig
    type t [@@deriving yojson, show]

    module Yojson_meta : sig
      val keys : string list
    end
  end

  module type Additional = sig
    type t [@@deriving yojson, show]
  end

  module Make (P : Primary) (A : Additional) = struct
    (* Helper type for printing the string *)
    type additional_show = (string * A.t) list [@@deriving show]

    type t = {
      primary : P.t;
      additional : A.t String_map.t;
          [@printer fun fmt v -> pp_additional_show fmt (String_map.to_list v)]
    }
    [@@deriving show]

    let rec additional_of_yojson acc keys = function
      | [] -> Ok acc
      | (name, _) :: vs when CCList.mem ~eq:CCString.equal name keys ->
          additional_of_yojson acc keys vs
      | (name, v) :: vs ->
          let open CCResult.Infix in
          A.of_yojson v >>= fun v -> additional_of_yojson (String_map.add name v acc) keys vs

    let of_yojson json =
      let open CCResult.Infix in
      P.of_yojson json
      >>= fun primary ->
      additional_of_yojson String_map.empty P.Yojson_meta.keys (Yojson.Safe.Util.to_assoc json)
      >>= fun additional -> Ok { primary; additional }

    let to_yojson { primary; additional } =
      Yojson.Safe.Util.combine
        (P.to_yojson primary)
        (`Assoc
          (CCList.map (fun (name, v) -> (name, A.to_yojson v)) (String_map.to_list additional)))

    let value { primary; _ } = primary
    let additional { additional; _ } = additional
  end
end

module Obj = struct
  type t = Yojson.Safe.t [@@deriving yojson, show]
end

module Empty_obj = struct
  type t = unit

  let of_yojson = function
    | `Assoc _ -> Ok ()
    | _ -> Error "not an object"

  let to_yojson () = `Assoc []
  let pp fmt () = Format.fprintf fmt "{}"
  let show () = "{}"

  module Yojson_meta = struct
    let keys = []
  end
end

module Format = struct
  module Uri = struct
    type t = Uri.t [@@deriving show]

    let pp fmt uri = Format.pp_print_string fmt (Uri.to_string uri)
    let to_yojson uri = Uri.to_string uri |> [%to_yojson: string]

    let of_yojson s =
      match [%of_yojson: string] s with
      | Ok s -> Ok (Uri.of_string s)
      | Error _ -> Error (Printf.sprintf "Excepted URI, got '%s'" (Yojson.Safe.to_string s))
  end

  module Uritmpl = struct
    type t = Uritmpl.t

    let pp fmt uritmpl = Format.pp_print_string fmt (Uritmpl.to_string uritmpl)

    let show uritmpl =
      let buf = Buffer.create 10 in
      let formatter = Format.formatter_of_buffer buf in
      pp formatter uritmpl;
      Format.pp_print_flush formatter ();
      Buffer.contents buf

    let to_yojson tmpl = Uritmpl.to_string tmpl |> [%to_yojson: string]

    let of_yojson s =
      match [%of_yojson: string] s with
      | Ok s -> (
          match Uritmpl.of_string s with
          | Ok t -> Ok t
          | Error _ -> Error (Printf.sprintf "Failed to parse URI Template '%s'" s))
      | Error _ ->
          Error (Printf.sprintf "Excepted URI Template, got '%s'" (Yojson.Safe.to_string s))
  end

  module Date_time = struct
    type t = float [@@deriving yojson, show]
  end
end

let one_of fs yojson =
  match
    CCList.filter_map
      (fun f ->
        match f yojson with
        | Ok v -> Some v
        | Error err -> None)
      fs
  with
  | [] -> Error ("oneOf: No valid match:\n" ^ Yojson.Safe.to_string yojson)
  | [ v ] -> Ok v
  | _ :: _ -> Error ("oneOf: More than one matching schema:\n" ^ Yojson.Safe.to_string yojson)

let rec any_of fs yojson =
  match fs with
  | [] -> Error ("anyOf: Failed to convert:\n" ^ Yojson.Safe.to_string yojson)
  | f :: fs -> (
      match f yojson with
      | Ok t -> Ok t
      | Error _ -> any_of fs yojson)
