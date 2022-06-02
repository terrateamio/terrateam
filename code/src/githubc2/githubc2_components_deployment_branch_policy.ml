module Primary = struct
  type t = {
    custom_branch_policies : bool;
    protected_branches : bool;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
