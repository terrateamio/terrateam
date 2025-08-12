type t = {
  email : string;
  skip_confirmation : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
