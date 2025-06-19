module Variables = struct
  include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
end

type t = {
  token : string;
  variables : Variables.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
