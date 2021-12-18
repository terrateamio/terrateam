module Work_manifest_result = struct
  module Output = struct
    module Additional = struct
      type t = string [@@deriving yojson { strict = false; meta = true }, show]
    end

    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Additional)
  end

  type t = {
    output : Output.t;
    path : string;
    success : bool;
    workspace : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Plan_create = struct
  type t = {
    path : string;
    plan_data : string;
    workspace : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Work_manifest_initiate = struct
  type t = {
    run_id : string;
    sha : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Work_manifest_dir = struct
  type t = {
    path : string;
    rank : int;
    workflow : int option; [@default None]
    workspace : string;
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Work_manifest_results = struct
  type t = Work_manifest_result.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Work_manifest_apply = struct
  module Dirs = struct
    type t = Work_manifest_dir.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Type = struct
    let t_of_yojson = function
      | `String "apply" -> Ok "apply"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    base_ref : string;
    dirs : Dirs.t;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Work_manifest_plan = struct
  module Dirs = struct
    type t = Work_manifest_dir.t list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Type = struct
    let t_of_yojson = function
      | `String "plan" -> Ok "plan"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    base_ref : string;
    dirs : Dirs.t;
    type_ : Type.t; [@key "type"]
  }
  [@@deriving yojson { strict = true; meta = true }, show]
end

module Work_manifest = struct
  type t =
    | Work_manifest_plan of Work_manifest_plan.t
    | Work_manifest_apply of Work_manifest_apply.t
  [@@deriving show]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
      [
        (fun v -> map (fun v -> Work_manifest_plan v) (Work_manifest_plan.of_yojson v));
        (fun v -> map (fun v -> Work_manifest_apply v) (Work_manifest_apply.of_yojson v));
      ])

  let to_yojson = function
    | Work_manifest_plan v -> Work_manifest_plan.to_yojson v
    | Work_manifest_apply v -> Work_manifest_apply.to_yojson v
end
