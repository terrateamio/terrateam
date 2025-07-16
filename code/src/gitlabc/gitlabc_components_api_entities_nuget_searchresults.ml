module Data = struct
  type t = Gitlabc_components_api_entities_nuget_searchresult.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  data : Data.t option; [@default None]
  totalhits : int option; [@default None] [@key "totalHits"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
