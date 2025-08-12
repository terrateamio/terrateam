module Feature_categories = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  feature_categories : Feature_categories.t option; [@default None]
  table_name : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
