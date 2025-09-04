module Primary = struct
  module Public_ips = struct
    type t = Githubc2_components_public_ip.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Status_ = struct
    let t_of_yojson = function
      | `String "Ready" -> Ok "Ready"
      | `String "Provisioning" -> Ok "Provisioning"
      | `String "Shutdown" -> Ok "Shutdown"
      | `String "Deleting" -> Ok "Deleting"
      | `String "Stuck" -> Ok "Stuck"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    id : int;
    image_details : Githubc2_components_nullable_actions_hosted_runner_pool_image.t option;
        [@default None]
    last_active_on : string option; [@default None]
    machine_size_details : Githubc2_components_actions_hosted_runner_machine_spec.t;
    maximum_runners : int; [@default 10]
    name : string;
    platform : string;
    public_ip_enabled : bool;
    public_ips : Public_ips.t option; [@default None]
    runner_group_id : int option; [@default None]
    status : Status_.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
