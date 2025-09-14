module Data = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  committed : bool option; [@default None]
  data : Data.t;
  idx : int option; [@default None]
  version : int option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
