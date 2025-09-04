module Merge_access_levels = struct
  type t = Gitlabc_components_api_entities_protectedrefaccess.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Push_access_levels = struct
  type t = Gitlabc_components_api_entities_protectedrefaccess.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Unprotect_access_levels = struct
  type t = Gitlabc_components_api_entities_protectedrefaccess.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  allow_force_push : bool option; [@default None]
  code_owner_approval_required : bool option; [@default None]
  id : int option; [@default None]
  inherited : bool option; [@default None]
  merge_access_levels : Merge_access_levels.t option; [@default None]
  name : string option; [@default None]
  push_access_levels : Push_access_levels.t option; [@default None]
  unprotect_access_levels : Unprotect_access_levels.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
