type t = {
  content : string;
  dry_run : bool; [@default false]
  include_jobs : bool option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
