module Items = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
