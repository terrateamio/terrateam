let src = Logs.Src.create "terrat_vcs_api_github"

module Logs = (val Logs.src_log src : Logs.LOG)

let cache_capacity_mb_in_kb = ( * ) 1024
let kb_of_bytes b = CCInt.max 1 (b / 1024)
let fetch_pull_request_tries = 6
let fetch_file_length_of_git_hash = CCString.length "aa2022e256fc3435d05d9d8ca0ef0ad0805e6ea5"

let probably_is_git_hash =
  CCString.for_all (function
    | '0' .. '9' | 'a' .. 'f' -> true
    | _ -> false)

module Metrics = struct
  let namespace = "terrat"
  let subsystem = "vcs_api_github"

  let cache_fn_call_count =
    let help = "Count of cache calls by function with hit or miss or evict" in
    let family =
      Prmths.Counter.v_labels
        ~label_names:[ "lifetime"; "fn"; "type" ]
        ~help
        ~namespace
        ~subsystem
        "cache_fn_call_count"
    in
    fun ~l ~fn t -> Prmths.Counter.labels family [ l; fn; t ]

  let github_errors_total = Terrat_metrics.errors_total ~m:subsystem ~t:"github"

  let fetch_pull_request_errors_total =
    let help = "Number of errors in fetching a pull request" in
    Prmths.Counter.v ~help ~namespace ~subsystem "fetch_pull_request_errors_total"

  let pull_request_mergeable_state_count =
    let help = "Counts for the different mergeable states in pull requests fetches" in
    Prmths.Counter.v_label
      ~label_name:"mergeable_state"
      ~help
      ~namespace
      ~subsystem
      "pull_request_mergeable_state_count"
end

module User = struct
  module Id = struct
    type t = string [@@deriving yojson, show, eq]

    let of_string = CCOption.return
    let to_string = CCFun.id
  end

  type t = string [@@deriving yojson]

  let make = CCFun.id
  let id = CCFun.id
  let to_string = CCFun.id
end

module Account = struct
  module Id = struct
    type t = int [@@deriving yojson, show, eq]

    let of_string = CCInt.of_string
    let to_string = CCInt.to_string
  end

  type t = { installation_id : int } [@@deriving make, yojson, eq]

  let make installation_id = { installation_id }
  let to_string t = CCInt.to_string t.installation_id
end

module Repo = struct
  module Id = struct
    type t = int [@@deriving yojson, show, eq]

    let of_string = CCInt.of_string
    let to_string = CCInt.to_string
  end

  type t = {
    id : int;
    name : string;
    owner : string;
  }
  [@@deriving eq, yojson]

  let make ~id ~name ~owner () = { id; name; owner }
  let name t = t.name
  let owner t = t.owner
  let to_string t = t.owner ^ "/" ^ t.name
end

module Remote_repo = struct
  module R = Githubc2_components.Full_repository
  module U = Githubc2_components.Simple_user

  type t = R.t [@@deriving yojson]

  let to_repo
      {
        R.primary =
          { R.Primary.id; owner = { U.primary = { U.Primary.login = owner; _ }; _ }; name; _ };
        _;
      } =
    Repo.make ~id ~owner ~name ()

  let default_branch t = t.R.primary.R.Primary.default_branch
end

module Ref = struct
  type t = string [@@deriving eq, yojson]

  let to_string = CCFun.id
  let of_string = CCFun.id
end

module Pull_request = struct
  module Id = struct
    type t = int [@@deriving yojson, show, eq]

    let of_string = CCInt.of_string
    let to_string = CCInt.to_string
  end

  module Diff = struct
    type t = Terrat_change.Diff.t =
      | Add of { filename : string }
      | Change of { filename : string }
      | Remove of { filename : string }
      | Move of {
          filename : string;
          previous_filename : string;
        }
    [@@deriving yojson]
  end

  module State = struct
    module Merged = struct
      type t = Terrat_pull_request.State.Merged.t = {
        merged_hash : string;
        merged_at : string;
      }
      [@@deriving show, yojson]
    end

    module Open_status = struct
      type t = Terrat_pull_request.State.Open_status.t =
        | Mergeable
        | Merge_conflict
      [@@deriving show, yojson]
    end

    type t = Terrat_pull_request.State.t =
      | Open of Open_status.t
      | Closed
      | Merged of Merged.t
    [@@deriving show, yojson]
  end

  type t = {
    base_branch_name : Ref.t;
    base_ref : Ref.t;
    branch_name : Ref.t;
    branch_ref : Ref.t;
    checks : bool;
    diff : Diff.t list;
    id : int;
    is_draft_pr : bool;
    mergeable : bool option;
    provisional_merge_ref : Ref.t option;
    repo : Repo.t;
    state : State.t;
    title : string option;
    user : string option;
  }
  [@@deriving yojson]

  let base_branch_name t = t.base_branch_name
  let base_ref t = t.base_ref
  let branch_name t = t.branch_name
  let branch_ref t = t.branch_ref
  let diff t = t.diff
  let id t = t.id
  let is_draft_pr t = t.is_draft_pr
  let provisional_merge_ref t = t.provisional_merge_ref
  let pull_number t = t.id
  let repo t = t.repo
  let state t = t.state
end

module Client = struct
  let on_hit fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "hit")
  let on_miss fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "miss")
  let on_evict fn () = Prmths.Counter.inc_one (Metrics.cache_fn_call_count ~l:"global" ~fn "evict")

  module Client_cache = Abbs_cache.Expiring.Make (struct
    type k = Account.t [@@deriving eq]
    type v = Githubc2_abb.t
    type err = [ `Error ]
    type args = unit -> (v, err) result Abb.Future.t

    let fetch f = f ()
    let weight _ = 1
  end)

  module Fetch_file_cache = struct
    module M = struct
      type k = Account.t * Repo.t * Ref.t * string [@@deriving eq]
      type v = Githubc2_components.Content_file.t option
      type err = Terrat_github.fetch_file_err
      type args = unit -> (v, err) result Abb.Future.t

      let fetch f = f ()

      let weight v =
        CCOption.map_or
          ~default:1
          CCFun.(
            Githubc2_components.Content_file.to_yojson
            %> Yojson.Safe.to_string
            %> CCString.length
            %> kb_of_bytes)
          v
    end

    module By_rev = Abbs_cache.Expiring.Make (M)
  end

  module Fetch_repo_cache = Abbs_cache.Expiring.Make (struct
    type k = Account.t * (string * string) [@@deriving eq]
    type v = Remote_repo.t
    type err = Terrat_github.fetch_repo_err
    type args = unit -> (v, err) result Abb.Future.t

    let fetch f = f ()

    let weight remote_repo =
      kb_of_bytes (CCString.length (Yojson.Safe.to_string (Remote_repo.to_yojson remote_repo)))
  end)

  module Fetch_tree_cache = struct
    module M = struct
      type k = Account.t * Repo.t * Ref.t [@@deriving eq]
      type v = string list
      type err = Terrat_github.get_tree_err
      type args = unit -> (v, err) result Abb.Future.t

      let fetch f = f ()
      let weight v = kb_of_bytes (CCList.fold_left (fun weight v -> weight + CCString.length v) 0 v)
    end

    module By_rev = Abbs_cache.Expiring.Make (M)
  end

  module Globals = struct
    let client_cache =
      Client_cache.create
        {
          Abbs_cache.Expiring.on_hit = on_hit "create_client";
          on_miss = on_miss "create_client";
          on_evict = on_evict "create_client";
          duration = Duration.of_min 1;
          capacity = 500;
        }

    let fetch_file_by_rev_cache =
      Fetch_file_cache.By_rev.create
        {
          Abbs_cache.Expiring.on_hit = on_hit "fetch_file_by_rev";
          on_miss = on_miss "fetch_file_by_rev";
          on_evict = on_evict "fetch_file_by_rev";
          duration = Duration.of_min 10;
          capacity = cache_capacity_mb_in_kb 100;
        }

    let fetch_repo_cache =
      Fetch_repo_cache.create
        {
          Abbs_cache.Expiring.on_hit = on_hit "fetch_repo";
          on_miss = on_miss "fetch_repo";
          on_evict = on_evict "fetch_repo";
          duration = Duration.of_min 1;
          capacity = cache_capacity_mb_in_kb 20;
        }

    let fetch_tree_by_rev_cache =
      Fetch_tree_cache.By_rev.create
        {
          Abbs_cache.Expiring.on_hit = on_hit "fetch_tree_by_rev";
          on_miss = on_miss "fetch_tree_by_rev";
          on_evict = on_evict "fetch_tree_by_rev";
          duration = Duration.of_min 10;
          capacity = cache_capacity_mb_in_kb 100;
        }
  end

  type t = {
    account : Account.t;
    client : Githubc2_abb.t;
    config : Terrat_config.t;
    fetch_file_by_rev_cache : Fetch_file_cache.By_rev.t;
    fetch_repo_cache : Fetch_repo_cache.t;
    fetch_tree_by_rev_cache : Fetch_tree_cache.By_rev.t;
  }

  let make ~account ~client ~config () =
    {
      account;
      client;
      config;
      fetch_file_by_rev_cache = Globals.fetch_file_by_rev_cache;
      fetch_repo_cache = Globals.fetch_repo_cache;
      fetch_tree_by_rev_cache = Globals.fetch_tree_by_rev_cache;
    }
end

let fetch_branch_sha ~request_id client repo ref_ =
  let ret =
    let open Abbs_future_combinators.Infix_result_monad in
    let module B = Githubc2_components.Branch_with_protection in
    let module C = Githubc2_components.Commit in
    Terrat_github.fetch_branch
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~branch:ref_
      client.Client.client
    >>= fun { B.primary = { B.Primary.commit = { C.primary = { C.Primary.sha; _ }; _ }; _ }; _ } ->
    Abb.Future.return (Ok sha)
  in
  let open Abb.Future.Infix_monad in
  ret
  >>= function
  | Ok sha -> Abb.Future.return (Ok (Some sha))
  | Error (`Not_found _) -> Abb.Future.return (Ok None)
  | Error (#Terrat_github.fetch_branch_err as err) ->
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : FETCH_BRANCH_SHA : %a"
            request_id
            Terrat_github.pp_fetch_branch_err
            err);
      Abb.Future.return (Error `Error)

let fetch_file ~request_id client repo ref_ path =
  let module C = Githubc2_components.Content_file in
  let open Abb.Future.Infix_monad in
  (* If we think the reference looks like a git hash, we know that the content
       of the file will never change, so we cache that in an LRU cache.
       Otherwise, we use an expiring cache. *)
  let fetch () =
    Terrat_github.fetch_file
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~ref_
      ~path
      client.Client.client
  in
  (if CCString.length ref_ = fetch_file_length_of_git_hash && probably_is_git_hash ref_ then
     Client.Fetch_file_cache.By_rev.fetch
       client.Client.fetch_file_by_rev_cache
       (client.Client.account, repo, ref_, path)
       fetch
   else fetch ())
  >>= function
  | Ok (Some { C.primary = { C.Primary.encoding = "base64"; content; _ }; _ }) ->
      Abb.Future.return (Ok (Some (Base64.decode_exn (CCString.replace ~sub:"\n" ~by:"" content))))
  | Ok (Some { C.primary = { C.Primary.content; _ }; _ }) -> Abb.Future.return (Ok (Some content))
  | Ok None -> Abb.Future.return (Ok None)
  | Error (#Terrat_github.fetch_file_err as err) ->
      Logs.err (fun m ->
          m "GITHUB_EVALUATOR : %s : FETCH_FILE : %a" request_id Terrat_github.pp_fetch_file_err err);
      Abb.Future.return (Error `Error)

let fetch_remote_repo ~request_id client repo =
  let open Abb.Future.Infix_monad in
  let fetch () =
    Terrat_github.fetch_repo ~owner:repo.Repo.owner ~repo:repo.Repo.name client.Client.client
  in
  Client.Fetch_repo_cache.fetch
    client.Client.fetch_repo_cache
    (client.Client.account, (Repo.owner repo, Repo.name repo))
    fetch
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Terrat_github.fetch_repo_err as err) ->
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : FETCH_REMOTE_REPO : %a"
            request_id
            Terrat_github.pp_fetch_repo_err
            err);
      Abb.Future.return (Error `Error)

let fetch_centralized_repo ~request_id client owner =
  let centralized_repo_name = "terrateam" in
  let open Abb.Future.Infix_monad in
  let fetch () = Terrat_github.fetch_repo ~owner ~repo:centralized_repo_name client.Client.client in
  Client.Fetch_repo_cache.fetch
    client.Client.fetch_repo_cache
    (client.Client.account, (owner, centralized_repo_name))
    fetch
  >>= function
  | Ok r -> Abb.Future.return (Ok (Some r))
  | Error (`Not_found _) -> Abb.Future.return (Ok None)
  | Error (#Terrat_github.fetch_repo_err as err) ->
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : FETCH_CENTRALIZED_REPO : %a"
            request_id
            Terrat_github.pp_fetch_repo_err
            err);
      Abb.Future.return (Error `Error)

let create_client' config { Account.installation_id } =
  let open Abbs_future_combinators.Infix_result_monad in
  Terrat_github.get_installation_access_token config installation_id
  >>= fun access_token ->
  let github_client = Terrat_github.create config (`Token access_token) in
  Abb.Future.return (Ok github_client)

let create_client ~request_id config account =
  let open Abb.Future.Infix_monad in
  let fetch () =
    create_client' config account
    >>= function
    | Ok _ as ret -> Abb.Future.return ret
    | Error (#Terrat_github.get_installation_access_token_err as err) ->
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s: ERROR : %a"
              request_id
              Terrat_github.pp_get_installation_access_token_err
              err);
        Abb.Future.return (Error `Error)
  in
  Client.Client_cache.fetch Client.Globals.client_cache account fetch
  >>= function
  | Ok github_client ->
      Abb.Future.return (Ok (Client.make ~account ~client:github_client ~config ()))
  | Error `Error -> Abb.Future.return (Error `Error)

let fetch_tree ~request_id client repo ref_ =
  let open Abb.Future.Infix_monad in
  let fetch () =
    Terrat_github.get_tree
      ~owner:repo.Repo.owner
      ~repo:repo.Repo.name
      ~sha:ref_
      client.Client.client
  in
  (if CCString.length ref_ = fetch_file_length_of_git_hash && probably_is_git_hash ref_ then
     Client.Fetch_tree_cache.By_rev.fetch
       client.Client.fetch_tree_by_rev_cache
       (client.Client.account, repo, ref_)
       fetch
   else fetch ())
  >>= function
  | Ok _ as r -> Abb.Future.return r
  | Error (#Terrat_github.get_tree_err as err) ->
      Logs.err (fun m ->
          m "GITHUB_EVALUATOR : %s : FETCH_TREE : %a" request_id Terrat_github.pp_get_tree_err err);
      Abb.Future.return (Error `Error)

let comment_on_pull_request ~request_id client pull_request body =
  let open Abb.Future.Infix_monad in
  Terrat_github.publish_comment
    ~owner:(Repo.owner (Pull_request.repo pull_request))
    ~repo:(Repo.name (Pull_request.repo pull_request))
    ~pull_number:(Pull_request.pull_number pull_request)
    ~body
    client.Client.client
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Terrat_github.publish_comment_err as err) ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.err (fun m ->
          m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Terrat_github.pp_publish_comment_err err);
      Abb.Future.return (Error `Error)

let diff_of_github_diff =
  CCList.map
    Githubc2_components.Diff_entry.(
      function
      | { primary = { Primary.filename; status = "added" | "copied"; _ }; _ } ->
          Terrat_change.Diff.Add { filename }
      | { primary = { Primary.filename; status = "removed"; _ }; _ } ->
          Terrat_change.Diff.Remove { filename }
      | { primary = { Primary.filename; status = "modified" | "changed" | "unchanged"; _ }; _ } ->
          Terrat_change.Diff.Change { filename }
      | {
          primary =
            { Primary.filename; status = "renamed"; previous_filename = Some previous_filename; _ };
          _;
        } -> Terrat_change.Diff.Move { filename; previous_filename }
      | _ -> failwith "nyi1")

let fetch_diff ~client ~owner ~repo pull_number =
  let open Abbs_future_combinators.Infix_result_monad in
  Terrat_github.fetch_pull_request_files ~owner ~repo ~pull_number client.Client.client
  >>= fun github_diff ->
  let diff = diff_of_github_diff github_diff in
  Abb.Future.return (Ok diff)

let fetch_pull_request' request_id account client repo pull_request_id =
  let owner = repo.Repo.owner in
  let repo_name = repo.Repo.name in
  let open Abbs_future_combinators.Infix_result_monad in
  Abbs_future_combinators.Infix_result_app.(
    (fun resp diff -> (resp, diff))
    <$> Terrat_github.fetch_pull_request
          ~owner
          ~repo:repo_name
          ~pull_number:pull_request_id
          client.Client.client
    <*> fetch_diff ~client ~owner ~repo:repo_name pull_request_id)
  >>= fun (resp, diff) ->
  let module Ghc_comp = Githubc2_components in
  let module Pr = Ghc_comp.Pull_request in
  let module Head = Pr.Primary.Head in
  let module Base = Pr.Primary.Base in
  let module User = Ghc_comp.Simple_user in
  match Openapi.Response.value resp with
  | `OK
      {
        Ghc_comp.Pull_request.primary =
          {
            Ghc_comp.Pull_request.Primary.head;
            base;
            state;
            merged;
            merged_at;
            merge_commit_sha;
            mergeable_state;
            mergeable;
            draft;
            title;
            user = User.{ primary = Primary.{ login; _ }; _ };
            _;
          };
        _;
      } ->
      let base_branch_name = Base.(base.primary.Primary.ref_) in
      let base_sha = Base.(base.primary.Primary.sha) in
      let head_sha = Head.(head.primary.Primary.sha) in
      let branch_name = Head.(head.primary.Primary.ref_) in
      let draft = CCOption.get_or ~default:false draft in
      Prmths.Counter.inc_one (Metrics.pull_request_mergeable_state_count mergeable_state);
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : MERGEABLE : merged=%s : mergeable_state=%s : \
             merge_commit_sha=%s"
            request_id
            (Bool.to_string merged)
            mergeable_state
            (CCOption.get_or ~default:"" merge_commit_sha));
      Abb.Future.return
        (Ok
           ( mergeable_state,
             {
               Pull_request.base_branch_name;
               base_ref = base_sha;
               branch_name;
               branch_ref = head_sha;
               id = pull_request_id;
               state =
                 (match (merge_commit_sha, state, merged, merged_at) with
                 | Some _, "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Mergeable)
                 | None, "open", _, _ -> Terrat_pull_request.State.(Open Open_status.Merge_conflict)
                 | Some merge_commit_sha, "closed", true, Some merged_at ->
                     Terrat_pull_request.State.(
                       Merged Merged.{ merged_hash = merge_commit_sha; merged_at })
                 | _, "closed", false, _ -> Terrat_pull_request.State.Closed
                 | _, _, _, _ -> assert false);
               title = Some title;
               user = Some login;
               repo;
               checks =
                 merged
                 || CCList.mem
                      ~eq:CCString.equal
                      mergeable_state
                      [ "clean"; "unstable"; "has_hooks" ];
               diff;
               is_draft_pr = draft;
               mergeable;
               provisional_merge_ref = merge_commit_sha;
             } ))
  | (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as err ->
      Abb.Future.return (Error err)

let fetch_pull_request ~request_id account client repo pull_request_id =
  let open Abb.Future.Infix_monad in
  let fetch () = fetch_pull_request' request_id account client repo pull_request_id in
  let f () =
    fetch ()
    >>= function
    | Ok ret -> Abb.Future.return (Ok ret)
    | Error (`Not_found _ | `Internal_server_error _ | `Not_modified | `Service_unavailable _) as
      err -> Abb.Future.return err
    | Error `Error ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m "GITHUB_EVALUATOR : %s : ERROR : repo=%s : ERROR" request_id (Repo.to_string repo));
        Abb.Future.return (Error `Error)
    | Error (#Terrat_github.compare_commits_err as err) ->
        Prmths.Counter.inc_one Metrics.github_errors_total;
        Logs.err (fun m ->
            m
              "GITHUB_EVALUATOR : %s : ERROR : repo=%s : %a"
              request_id
              (Repo.to_string repo)
              Terrat_github.pp_compare_commits_err
              err);
        Abb.Future.return (Error `Error)
  in
  Abbs_future_combinators.retry
    ~f
    ~while_:
      (Abbs_future_combinators.finite_tries fetch_pull_request_tries (function
        | Error _ | Ok ("unknown", { Pull_request.state = Terrat_pull_request.State.Open _; _ }) ->
            true
        | Ok _ -> false))
    ~betwixt:
      (Abbs_future_combinators.series ~start:2.0 ~step:(( *. ) 1.5) (fun n _ ->
           Prmths.Counter.inc_one Metrics.fetch_pull_request_errors_total;
           Abb.Sys.sleep (CCFloat.min n 8.0)))
  >>= function
  | Ok (_, ret) -> Abb.Future.return (Ok ret)
  | Error (`Not_found _)
  | Error (`Internal_server_error _)
  | Error `Not_modified
  | Error (`Service_unavailable _)
  | Error `Error -> Abb.Future.return (Error `Error)

let react_to_comment ~request_id client repo comment_id =
  let open Abb.Future.Infix_monad in
  Terrat_github.react_to_comment
    ~owner:(Repo.owner repo)
    ~repo:(Repo.name repo)
    ~comment_id
    client.Client.client
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Terrat_github.publish_reaction_err as err) ->
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : REACT_TO_COMMENT : %a"
            request_id
            Terrat_github.pp_publish_reaction_err
            err);
      Abb.Future.return (Error `Error)

let create_commit_checks ~request_id client repo ref_ checks =
  let open Abb.Future.Infix_monad in
  Logs.info (fun m ->
      m "GITHUB_EVALUATOR : %s : CREATE_COMMIT_CHECKS : num=%d" request_id (CCList.length checks));
  Terrat_vcs_api_github_commit_check.create
    ~owner:(Repo.owner repo)
    ~repo:(Repo.name repo)
    ~ref_
    ~checks
    client.Client.client
  >>= function
  | Ok () -> Abb.Future.return (Ok ())
  | Error (#Githubc2_abb.call_err as err) ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.err (fun m ->
          m "GITHUB_EVALUATOR : %s : ERROR : %a" request_id Githubc2_abb.pp_call_err err);
      Abb.Future.return (Error `Error)

let fetch_commit_checks ~request_id client repo ref_ =
  let open Abb.Future.Infix_monad in
  let owner = Repo.owner repo in
  let repo = Repo.name repo in
  Abbs_time_it.run
    (fun time ->
      Logs.info (fun m -> m "GITHUB_EVALUATOR : %s : LIST_COMMIT_CHECKS : %f" request_id time))
    (fun () ->
      Terrat_vcs_api_github_commit_check.list
        ~log_id:request_id
        ~owner
        ~repo
        ~ref_
        client.Client.client)
  >>= function
  | Ok _ as res -> Abb.Future.return res
  | Error (#Terrat_vcs_api_github_commit_check.list_err as err) ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : FETCH_COMMIT_CHECKS : %a"
            request_id
            Terrat_vcs_api_github_commit_check.pp_list_err
            err);
      Abb.Future.return (Error `Error)

let fetch_pull_request_reviews ~request_id client pull_request =
  let open Abb.Future.Infix_monad in
  let repo = Pull_request.repo pull_request in
  let owner = Repo.owner repo in
  let repo = Repo.name repo in
  let pull_number = pull_request.Pull_request.id in
  Terrat_github.Pull_request_reviews.list ~owner ~repo ~pull_number client.Client.client
  >>= function
  | Ok reviews ->
      let module Prr = Githubc2_components.Pull_request_review in
      Abb.Future.return
        (Ok
           (CCList.map
              (fun Prr.{ primary = Primary.{ node_id; state; user; _ }; _ } ->
                Terrat_pull_request_review.
                  {
                    id = node_id;
                    status =
                      (match state with
                      | "APPROVED" -> Status.Approved
                      | _ -> Status.Unknown);
                    user =
                      CCOption.map
                        (fun Githubc2_components.Nullable_simple_user.
                               { primary = Primary.{ login; _ }; _ }
                           -> login)
                        user;
                  })
              reviews))
  | Error (#Terrat_github.Pull_request_reviews.list_err as err) ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.err (fun m ->
          m
            "GITHUB_EVALUATOR : %s : ERROR : %a"
            request_id
            Terrat_github.Pull_request_reviews.pp_list_err
            err);
      Abb.Future.return (Error `Error)

let merge_pull_request' request_id client pull_request =
  let open Abbs_future_combinators.Infix_result_monad in
  let repo = pull_request.Pull_request.repo in
  Logs.info (fun m ->
      m
        "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %s : %s : %d"
        request_id
        repo.Repo.owner
        repo.Repo.name
        pull_request.Pull_request.id);
  Githubc2_abb.call
    client.Client.client
    Githubc2_pulls.Merge.(
      make
        ~body:
          Request_body.(
            make
              Primary.(
                make
                  ~commit_title:
                    (Some (Printf.sprintf "Terrateam Automerge #%d" pull_request.Pull_request.id))
                  ()))
        Parameters.(
          make ~owner:repo.Repo.owner ~repo:repo.Repo.name ~pull_number:pull_request.Pull_request.id))
  >>= fun resp ->
  let module Mna = Githubc2_pulls.Merge.Responses.Method_not_allowed in
  match Openapi.Response.value resp with
  | `OK _ -> Abb.Future.return (Ok ())
  | `Method_not_allowed { Mna.primary = { Mna.Primary.message = Some message; _ }; _ }
    when CCString.equal "Merge already in progress" message -> Abb.Future.return (Ok ())
  | `Method_not_allowed _ -> (
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : MERGE_METHOD_NOT_ALLOWED : %s : %s : %d"
            request_id
            repo.Repo.owner
            repo.Repo.name
            pull_request.Pull_request.id);
      Githubc2_abb.call
        client.Client.client
        Githubc2_pulls.Merge.(
          make
            ~body:Request_body.(make Primary.(make ~merge_method:(Some "squash") ()))
            Parameters.(
              make
                ~owner:repo.Repo.owner
                ~repo:repo.Repo.name
                ~pull_number:pull_request.Pull_request.id))
      >>= fun resp ->
      match Openapi.Response.value resp with
      | `OK _ -> Abb.Future.return (Ok ())
      | (`Method_not_allowed _ | `Conflict _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _)
        as err -> Abb.Future.return (Error err))
  | (`Conflict _ | `Forbidden _ | `Not_found _ | `Unprocessable_entity _) as err ->
      Abb.Future.return (Error err)

let merge_pull_request ~request_id client pull_request =
  let num_tries = 3 in
  let sleep_time = Duration.(to_f (of_sec 2)) in
  Abbs_future_combinators.retry
    ~f:(fun () ->
      let open Abb.Future.Infix_monad in
      merge_pull_request' request_id client pull_request
      >>= function
      | Ok _ as ret -> Abb.Future.return ret
      | Error (#Githubc2_abb.call_err as err) ->
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                request_id
                Githubc2_abb.pp_call_err
                err);
          Abb.Future.return (Error `Error)
      | Error
          (( `Method_not_allowed
               Githubc2_pulls.Merge.Responses.Method_not_allowed.
                 { primary = Primary.{ message = Some message; _ }; _ }
           | `Conflict
               Githubc2_pulls.Merge.Responses.Conflict.
                 { primary = Primary.{ message = Some message; _ }; _ } ) as err) ->
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                request_id
                Githubc2_pulls.Merge.Responses.pp
                err);
          Abb.Future.return (Error (`Merge_err message))
      | Error (#Githubc2_pulls.Merge.Responses.t as err) ->
          Logs.info (fun m ->
              m
                "GITHUB_EVALUATOR : %s : MERGE_PULL_REQUEST : %a"
                request_id
                Githubc2_pulls.Merge.Responses.pp
                err);
          Abb.Future.return (Error `Error))
    ~while_:
      (Abbs_future_combinators.finite_tries num_tries (function
        | Error (`Merge_err _) -> true
        | Ok _ | Error _ -> false))
    ~betwixt:(fun _ -> Abb.Sys.sleep sleep_time)

let delete_branch' request_id client repo branch =
  let open Abbs_future_combinators.Infix_result_monad in
  Logs.info (fun m ->
      m
        "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %s"
        request_id
        repo.Repo.owner
        repo.Repo.name
        branch);
  Githubc2_abb.call
    client.Client.client
    Githubc2_git.Delete_ref.(
      make Parameters.(make ~owner:repo.Repo.owner ~repo:repo.Repo.name ~ref_:("heads/" ^ branch)))
  >>= fun resp ->
  match Openapi.Response.value resp with
  | `No_content -> Abb.Future.return (Ok ())
  | `Unprocessable_entity err ->
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %s : %s : %s : %a"
            request_id
            repo.Repo.owner
            repo.Repo.name
            branch
            Githubc2_git.Delete_ref.Responses.Unprocessable_entity.pp
            err);
      Abb.Future.return (Ok ())

let delete_branch ~request_id client repo branch =
  let open Abb.Future.Infix_monad in
  delete_branch' request_id client repo branch
  >>= function
  | Ok _ as ret -> Abb.Future.return ret
  | Error (#Githubc2_abb.call_err as err) ->
      Prmths.Counter.inc_one Metrics.github_errors_total;
      Logs.info (fun m ->
          m
            "GITHUB_EVALUATOR : %s : DELETE_PULL_REQUEST_BRANCH : %a"
            request_id
            Githubc2_abb.pp_call_err
            err);
      Abb.Future.return (Error `Error)
  | Error `Error -> Abb.Future.return (Error `Error)
