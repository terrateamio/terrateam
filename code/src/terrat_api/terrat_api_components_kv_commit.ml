module Keys = struct
  module Items = struct
    type t = {
      idx : int option; [@default None]
      key : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { keys : Keys.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
