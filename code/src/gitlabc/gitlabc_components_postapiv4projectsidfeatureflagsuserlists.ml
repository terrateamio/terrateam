type t = {
  name : string;
  user_xids : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
