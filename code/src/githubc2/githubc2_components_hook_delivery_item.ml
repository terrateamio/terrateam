module Primary = struct
  type t = {
    action : string option;
    delivered_at : string;
    duration : float;
    event : string;
    guid : string;
    id : int;
    installation_id : int option;
    redelivery : bool;
    repository_id : int option;
    status : string;
    status_code : int;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
