type t = {
  enabled : bool; [@default false]
  script : string option; [@default None]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
