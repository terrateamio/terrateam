module Custom_attributes = struct
  type t = Gitlabc_components_api_entities_customattribute.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  avatar_path : string option; [@default None]
  avatar_url : string option; [@default None]
  custom_attributes : Custom_attributes.t option; [@default None]
  id : int;
  locked : bool option; [@default None]
  name : string option; [@default None]
  state : string;
  username : string;
  web_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
