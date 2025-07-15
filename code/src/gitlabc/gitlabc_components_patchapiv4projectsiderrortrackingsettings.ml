type t = {
  active : bool;
  integrated : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
