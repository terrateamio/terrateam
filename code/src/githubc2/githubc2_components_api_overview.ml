module Primary = struct
  module Actions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Api = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependabot = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Git = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Hooks = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Importer = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Packages = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Pages = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Ssh_key_fingerprints = struct
    module Primary = struct
      type t = {
        sha256_dsa : string option; [@default None] [@key "SHA256_DSA"]
        sha256_ecdsa : string option; [@default None] [@key "SHA256_ECDSA"]
        sha256_ed25519 : string option; [@default None] [@key "SHA256_ED25519"]
        sha256_rsa : string option; [@default None] [@key "SHA256_RSA"]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Ssh_keys = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Web = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    actions : Actions.t option; [@default None]
    api : Api.t option; [@default None]
    dependabot : Dependabot.t option; [@default None]
    git : Git.t option; [@default None]
    hooks : Hooks.t option; [@default None]
    importer : Importer.t option; [@default None]
    packages : Packages.t option; [@default None]
    pages : Pages.t option; [@default None]
    ssh_key_fingerprints : Ssh_key_fingerprints.t option; [@default None]
    ssh_keys : Ssh_keys.t option; [@default None]
    verifiable_password_authentication : bool;
    web : Web.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
