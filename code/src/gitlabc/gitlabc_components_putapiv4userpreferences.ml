type t = {
  pass_user_identities_to_ci_jwt : bool option; [@default None]
  show_whitespace_in_diffs : bool option; [@default None]
  view_diffs_file_by_file : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
