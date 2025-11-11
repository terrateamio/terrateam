module Data = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Read_caps = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Write_caps = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  committed : bool;
  created_at : string;
  data : Data.t;
  idx : int;
  key : string;
  read_caps : Read_caps.t option; [@default None]
  size : int;
  version : int;
  write_caps : Write_caps.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
