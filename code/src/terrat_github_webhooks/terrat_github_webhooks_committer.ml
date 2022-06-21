type t = {
  date : string option; [@default None]
  email : string option; [@default None]
  name : string;
  username : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, make, show]
