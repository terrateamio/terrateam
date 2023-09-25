module Primary = struct
  module Labels = struct
    type t = Githubc2_components_runner_label.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    busy : bool;
    id : int;
    labels : Labels.t;
    name : string;
    os : string;
    runner_group_id : int option; [@default None]
    status : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
