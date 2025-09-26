module Results = struct
  type t = Terrat_api_components_access_token_create.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = { results : Results.t } [@@deriving yojson { strict = false; meta = true }, show, eq]
