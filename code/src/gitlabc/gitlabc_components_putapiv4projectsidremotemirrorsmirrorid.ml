type t = {
  auth_method : string option; [@default None]
  enabled : bool option; [@default None]
  keep_divergent_refs : bool option; [@default None]
  mirror_branch_regex : string option; [@default None]
  only_protected_branches : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
