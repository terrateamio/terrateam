module Access_token_create = Terrat_access_token_caps_access_token_create
module Access_token_refresh = Terrat_access_token_caps_access_token_refresh
module Installation_id = Terrat_access_token_caps_installation_id
module Kv_store_read = Terrat_access_token_caps_kv_store_read
module Kv_store_write = Terrat_access_token_caps_kv_store_write
module Vcs = Terrat_access_token_caps_vcs

module Event = struct
  type t =
    | Access_token_refresh of Terrat_access_token_caps_access_token_refresh.t
    | Access_token_create of Terrat_access_token_caps_access_token_create.t
    | Kv_store_read of Terrat_access_token_caps_kv_store_read.t
    | Kv_store_write of Terrat_access_token_caps_kv_store_write.t
    | Installation_id of Terrat_access_token_caps_installation_id.t
    | Vcs of Terrat_access_token_caps_vcs.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v ->
           map
             (fun v -> Access_token_refresh v)
             (Terrat_access_token_caps_access_token_refresh.of_yojson v));
         (fun v ->
           map
             (fun v -> Access_token_create v)
             (Terrat_access_token_caps_access_token_create.of_yojson v));
         (fun v ->
           map (fun v -> Kv_store_read v) (Terrat_access_token_caps_kv_store_read.of_yojson v));
         (fun v ->
           map (fun v -> Kv_store_write v) (Terrat_access_token_caps_kv_store_write.of_yojson v));
         (fun v ->
           map (fun v -> Installation_id v) (Terrat_access_token_caps_installation_id.of_yojson v));
         (fun v -> map (fun v -> Vcs v) (Terrat_access_token_caps_vcs.of_yojson v));
       ])

  let to_yojson = function
    | Access_token_refresh v -> Terrat_access_token_caps_access_token_refresh.to_yojson v
    | Access_token_create v -> Terrat_access_token_caps_access_token_create.to_yojson v
    | Kv_store_read v -> Terrat_access_token_caps_kv_store_read.to_yojson v
    | Kv_store_write v -> Terrat_access_token_caps_kv_store_write.to_yojson v
    | Installation_id v -> Terrat_access_token_caps_installation_id.to_yojson v
    | Vcs v -> Terrat_access_token_caps_vcs.to_yojson v
end
