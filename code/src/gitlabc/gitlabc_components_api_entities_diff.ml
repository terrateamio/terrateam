type t = {
  a_mode : string;
  b_mode : string;
  deleted_file : bool;
  diff : string;
  generated_file : bool option; [@default None]
  new_file : bool;
  new_path : string;
  old_path : string;
  renamed_file : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
