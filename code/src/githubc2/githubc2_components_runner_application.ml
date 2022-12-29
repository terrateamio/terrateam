module Primary = struct
  type t = {
    architecture : string;
    download_url : string;
    filename : string;
    os : string;
    sha256_checksum : string option; [@default None]
    temp_download_token : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
