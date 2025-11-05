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
  committed : bool option; [@default None]
  data : Data.t;
  idx : int option; [@default None]
  read_caps : Read_caps.t option; [@default None]
  write_caps : Write_caps.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
