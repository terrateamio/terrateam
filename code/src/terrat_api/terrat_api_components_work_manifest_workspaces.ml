module Items = struct
  type t = {
    dir : string;
    workspace : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
