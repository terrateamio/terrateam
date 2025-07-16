type t = {
  branch : string;
  dry_run : bool; [@default false]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
