module Config = struct
  type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { config : Config.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
