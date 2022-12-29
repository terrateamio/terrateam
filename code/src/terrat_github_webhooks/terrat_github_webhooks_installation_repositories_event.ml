type t =
  | Installation_repositories_added of Terrat_github_webhooks_installation_repositories_added.t
  | Installation_repositories_removed of Terrat_github_webhooks_installation_repositories_removed.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Installation_repositories_added v)
          (Terrat_github_webhooks_installation_repositories_added.of_yojson v));
      (fun v ->
        map
          (fun v -> Installation_repositories_removed v)
          (Terrat_github_webhooks_installation_repositories_removed.of_yojson v));
    ])

let to_yojson = function
  | Installation_repositories_added v ->
      Terrat_github_webhooks_installation_repositories_added.to_yojson v
  | Installation_repositories_removed v ->
      Terrat_github_webhooks_installation_repositories_removed.to_yojson v
