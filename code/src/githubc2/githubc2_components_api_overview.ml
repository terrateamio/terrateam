module Primary = struct
  module Actions = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Actions_macos = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Api = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Codespaces = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Copilot = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Dependabot = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Domains = struct
    module Primary = struct
      module Actions = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Actions_inbound = struct
        module Primary = struct
          module Full_domains = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          module Wildcard_domains = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            full_domains : Full_domains.t option; [@default None]
            wildcard_domains : Wildcard_domains.t option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Artifact_attestations = struct
        module Primary = struct
          module Services = struct
            type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = {
            services : Services.t option; [@default None]
            trust_domain : string option; [@default None]
          }
          [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
      end

      module Codespaces = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Copilot = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Packages = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      module Website = struct
        type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      type t = {
        actions : Actions.t option; [@default None]
        actions_inbound : Actions_inbound.t option; [@default None]
        artifact_attestations : Artifact_attestations.t option; [@default None]
        codespaces : Codespaces.t option; [@default None]
        copilot : Copilot.t option; [@default None]
        packages : Packages.t option; [@default None]
        website : Website.t option; [@default None]
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Git = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Github_enterprise_importer = struct
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
    actions_macos : Actions_macos.t option; [@default None]
    api : Api.t option; [@default None]
    codespaces : Codespaces.t option; [@default None]
    copilot : Copilot.t option; [@default None]
    dependabot : Dependabot.t option; [@default None]
    domains : Domains.t option; [@default None]
    git : Git.t option; [@default None]
    github_enterprise_importer : Github_enterprise_importer.t option; [@default None]
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
