type t = {
  pages_https_only : bool option; [@default None]
  pages_primary_domain : string option; [@default None]
  pages_unique_domain_enabled : bool option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
