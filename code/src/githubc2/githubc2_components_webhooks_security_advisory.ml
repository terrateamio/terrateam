module Primary = struct
  module Cvss = struct
    module Primary = struct
      type t = {
        score : float;
        vector_string : string option;
      }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Cwes = struct
    module Items = struct
      module Primary = struct
        type t = {
          cwe_id : string;
          name : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Identifiers = struct
    module Items = struct
      module Primary = struct
        type t = {
          type_ : string; [@key "type"]
          value : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module References = struct
    module Items = struct
      module Primary = struct
        type t = { url : string } [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Vulnerabilities = struct
    module Items = struct
      module Primary = struct
        module First_patched_version = struct
          module Primary = struct
            type t = { identifier : string }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        module Package_ = struct
          module Primary = struct
            type t = {
              ecosystem : string;
              name : string;
            }
            [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
        end

        type t = {
          first_patched_version : First_patched_version.t option;
          package : Package_.t;
          severity : string;
          vulnerable_version_range : string;
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    cvss : Cvss.t;
    cvss_severities : Githubc2_components_cvss_severities.t option; [@default None]
    cwes : Cwes.t;
    description : string;
    ghsa_id : string;
    identifiers : Identifiers.t;
    published_at : string;
    references : References.t;
    severity : string;
    summary : string;
    updated_at : string;
    vulnerabilities : Vulnerabilities.t;
    withdrawn_at : string option;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
