type t =
  | Installation_created of Terrat_github_webhooks_installation_created.t
  | Installation_deleted of Terrat_github_webhooks_installation_deleted.t
  | Installation_new_permissions_accepted of
      Terrat_github_webhooks_installation_new_permissions_accepted.t
  | Installation_suspend of Terrat_github_webhooks_installation_suspend.t
  | Installation_unsuspend of Terrat_github_webhooks_installation_unsuspend.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Installation_created v)
          (Terrat_github_webhooks_installation_created.of_yojson v));
      (fun v ->
        map
          (fun v -> Installation_deleted v)
          (Terrat_github_webhooks_installation_deleted.of_yojson v));
      (fun v ->
        map
          (fun v -> Installation_new_permissions_accepted v)
          (Terrat_github_webhooks_installation_new_permissions_accepted.of_yojson v));
      (fun v ->
        map
          (fun v -> Installation_suspend v)
          (Terrat_github_webhooks_installation_suspend.of_yojson v));
      (fun v ->
        map
          (fun v -> Installation_unsuspend v)
          (Terrat_github_webhooks_installation_unsuspend.of_yojson v));
    ])

let to_yojson = function
  | Installation_created v -> Terrat_github_webhooks_installation_created.to_yojson v
  | Installation_deleted v -> Terrat_github_webhooks_installation_deleted.to_yojson v
  | Installation_new_permissions_accepted v ->
      Terrat_github_webhooks_installation_new_permissions_accepted.to_yojson v
  | Installation_suspend v -> Terrat_github_webhooks_installation_suspend.to_yojson v
  | Installation_unsuspend v -> Terrat_github_webhooks_installation_unsuspend.to_yojson v
