type t = {
  branch : string;
  dry_run : bool; [@default false]
  message : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
