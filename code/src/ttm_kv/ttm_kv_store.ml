type err = Ttm_client.create_err [@@deriving show]

type t = {
  client : Ttm_client.t;
  installation : string;
  vcs : string;
}

type key = string [@@deriving to_yojson]
type path = string
type data = Yojson.Safe.t [@@deriving to_yojson]

module Record = struct
  type 'a t = {
    committed : bool;
    created_at : string;
    data : 'a;
    idx : int;
    key : key;
    size : int;
    version : int;
  }
  [@@deriving to_yojson]

  let committed t = t.committed
  let created_at t = t.created_at
  let data t = t.data
  let idx t = t.idx
  let key t = t.key
  let size t = t.size
  let version t = t.version
end

type data_record = data Record.t [@@deriving to_yojson]

module C = struct
  type 'a t = ('a, err) result Abb.Future.t
end

let create ~vcs ~installation client = { client; installation; vcs }

let get ?select ?idx ?committed ~key t =
  let open Abbs_future_combinators.Infix_result_monad in
  Ttm_client.call
    t.client
    Terrat_api_kv.Get.(
      make
        (Parameters.make ~select ~idx ~committed ~key ~vcs:t.vcs ~installation_id:t.installation ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Forbidden -> Abb.Future.return (Error `Refresh_token_err)
  | `Not_found -> Abb.Future.return (Ok None)
  | `OK { Terrat_api_components_kv_record.committed; created_at; data; idx; key; size; version } ->
      Abb.Future.return (Ok (Some { Record.committed; created_at; data; idx; key; size; version }))

let set ?idx ?committed ~key data t =
  let open Abbs_future_combinators.Infix_result_monad in
  let body = { Terrat_api_components_kv_set.committed; data; idx } in
  Ttm_client.call
    t.client
    Terrat_api_kv.Set.(make ~body (Parameters.make ~installation_id:t.installation ~vcs:t.vcs ~key))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK { Terrat_api_components_kv_record.committed; created_at; data = _; idx; key; size; version }
    ->
      (* Data returned from the server is empty, so we replace it with the data
         we just sent.  Gotta save those bytes. *)
      Abb.Future.return (Ok { Record.committed; created_at; data; idx; key; size; version })
  | `Forbidden -> Abb.Future.return (Error `Refresh_token_err)

let cas ?idx ?committed ?version ~key data t =
  let open Abbs_future_combinators.Infix_result_monad in
  let body = { Terrat_api_components_kv_cas.committed; data; idx; version } in
  Ttm_client.call
    t.client
    Terrat_api_kv.Cas.(make ~body (Parameters.make ~installation_id:t.installation ~vcs:t.vcs ~key))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK { Terrat_api_components_kv_record.committed; created_at; data = _; idx; key; size; version }
    ->
      (* Data returned from the server is empty, so we replace it with the data
         we just sent.  Gotta save those bytes. *)
      Abb.Future.return (Ok (Some { Record.committed; created_at; data; idx; key; size; version }))
  | `Bad_request -> Abb.Future.return (Ok None)
  | `Forbidden -> Abb.Future.return (Error `Refresh_token_err)

let delete ?idx ?version ~key t =
  let open Abbs_future_combinators.Infix_result_monad in
  Ttm_client.call
    t.client
    Terrat_api_kv.Delete.(
      make (Parameters.make ~installation_id:t.installation ~vcs:t.vcs ~idx ~version ~key ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK { Terrat_api_components_kv_delete.result } -> Abb.Future.return (Ok result)
  | `Forbidden -> Abb.Future.return (Error `Refresh_token_err)

let count ?committed ~key t = raise (Failure "nyi")
let size ?idx ?committed ~key t = raise (Failure "nyi")

let iter ?select ?idx ?inclusive ?prefix ?committed ?limit ~key t =
  let open Abbs_future_combinators.Infix_result_monad in
  Ttm_client.call
    t.client
    Terrat_api_kv.Iter.(
      make
        (Parameters.make
           ~select
           ~idx
           ~committed
           ~limit
           ~prefix
           ~inclusive
           ~key
           ~vcs:t.vcs
           ~installation_id:t.installation
           ()))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `Forbidden -> Abb.Future.return (Error `Refresh_token_err)
  | `OK { Terrat_api_components_kv_record_list.results } ->
      Abb.Future.return
        (Ok
           (CCList.map
              (fun {
                     Terrat_api_components_kv_record.committed;
                     created_at;
                     data;
                     idx;
                     key;
                     size;
                     version;
                   }
                 -> { Record.committed; created_at; data; idx; key; size; version })
              results))

let commit ~keys t =
  let open Abbs_future_combinators.Infix_result_monad in
  let body =
    {
      Terrat_api_components_kv_commit.keys =
        CCList.map (fun (key, idx) -> { Terrat_api_components_kv_commit.Keys.Items.key; idx }) keys;
    }
  in
  Ttm_client.call
    t.client
    Terrat_api_kv.Commit.(make ~body (Parameters.make ~installation_id:t.installation ~vcs:t.vcs))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `OK { Terrat_api_components_kv_commit_result.keys } ->
      Abb.Future.return
        (Ok
           (CCList.map
              (fun { Terrat_api_components_kv_commit_result.Keys.Items.key; idx } -> (key, idx))
              keys))
  | `Forbidden -> Abb.Future.return (Error `Refresh_token_err)
