module Data = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  committed : bool;
  created_at : string;
  data : Data.t;
  idx : int;
  key : string;
  size : int;
  version : int;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
