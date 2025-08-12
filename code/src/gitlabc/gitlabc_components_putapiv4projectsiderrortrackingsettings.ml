type t = {
  active : bool;
  integrated : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
