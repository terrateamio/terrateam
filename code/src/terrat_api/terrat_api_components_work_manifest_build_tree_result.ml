module Files = struct
  module Items = struct
    type t = {
      changed : bool option; [@default None]
      id : string option; [@default None]
      path : string;
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { files : Files.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
