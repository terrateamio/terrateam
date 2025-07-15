type t = {
  author_email : string option; [@default None]
  content : string;
  description : string option; [@default None]
  description_content_type : string option; [@default None]
  keywords : string option; [@default None]
  md5_digest : string option; [@default None]
  metadata_version : string option; [@default None]
  name : string;
  requires_python : string option; [@default None]
  sha256_digest : string option; [@default None]
  summary : string option; [@default None]
  version : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
