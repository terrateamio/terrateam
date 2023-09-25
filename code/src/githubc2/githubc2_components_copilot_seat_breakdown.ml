module Primary = struct
  type t = {
    active_this_cycle : int option; [@default None]
    added_this_cycle : int option; [@default None]
    inactive_this_cycle : int option; [@default None]
    pending_cancellation : int option; [@default None]
    pending_invitation : int option; [@default None]
    total : int option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
