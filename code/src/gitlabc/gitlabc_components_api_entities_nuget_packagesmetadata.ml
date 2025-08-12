module Items = struct
  type t = Gitlabc_components_api_entities_nuget_packagesmetadataitem.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  count : int option; [@default None]
  items : Items.t option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
