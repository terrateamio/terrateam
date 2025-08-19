module Primary = struct
  module Emails = struct
    module Items = struct
      module Primary = struct
        type t = {
          email : string option; [@default None]
          verified : bool option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Subkeys = struct
    module Items = struct
      module Primary = struct
        module Emails = struct
          module Items = struct
            module Primary = struct
              type t = {
                email : string option; [@default None]
                verified : bool option; [@default None]
              }
              [@@deriving yojson { strict = false; meta = true }, show, eq]
            end

            include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        module Subkeys = struct
          module Items = struct
            type t = Yojson.Safe.t [@@deriving yojson { strict = false; meta = true }, show, eq]
          end

          type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
        end

        type t = {
          can_certify : bool option; [@default None]
          can_encrypt_comms : bool option; [@default None]
          can_encrypt_storage : bool option; [@default None]
          can_sign : bool option; [@default None]
          created_at : string option; [@default None]
          emails : Emails.t option; [@default None]
          expires_at : string option; [@default None]
          id : int64 option; [@default None]
          key_id : string option; [@default None]
          primary_key_id : int option; [@default None]
          public_key : string option; [@default None]
          raw_key : string option; [@default None]
          revoked : bool option; [@default None]
          subkeys : Subkeys.t option; [@default None]
        }
        [@@deriving yojson { strict = false; meta = true }, show, eq]
      end

      include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
    end

    type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    can_certify : bool;
    can_encrypt_comms : bool;
    can_encrypt_storage : bool;
    can_sign : bool;
    created_at : string;
    emails : Emails.t;
    expires_at : string option; [@default None]
    id : int64;
    key_id : string;
    name : string option; [@default None]
    primary_key_id : int option; [@default None]
    public_key : string;
    raw_key : string option; [@default None]
    revoked : bool;
    subkeys : Subkeys.t;
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
