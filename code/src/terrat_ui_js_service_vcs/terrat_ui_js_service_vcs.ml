type create_err = [ `Error ] [@@deriving show]

module Api = struct
  module Io_err = struct
    type t = {
      name : string;
      message : string;
      stack : string;
    }
    [@@deriving show]

    let of_js_error err =
      {
        name = Jstr.to_string (Jv.Error.name err);
        message = Jstr.to_string (Jv.Error.message err);
        stack = Jstr.to_string (Jv.Error.stack err);
      }
  end

  type api_err =
    [ `Conversion_err of string * string Openapi.Response.t
    | `Missing_response of string Openapi.Response.t
    | `Io_err of (Jv.Error.t[@printer fun fmt v -> Io_err.(pp fmt (of_js_error v))])
    | `Forbidden
    | `Not_found
    ]
  [@@deriving show]

  type work_manifests_err =
    [ api_err
    | `Bad_request of Terrat_api_installations.List_work_manifests.Responses.Bad_request.t
    ]
  [@@deriving show]

  type work_manifest_outputs_err =
    [ api_err
    | `Bad_request of Terrat_api_installations.Get_work_manifest_outputs.Responses.Bad_request.t
    ]
  [@@deriving show]

  type dirspaces_err =
    [ api_err
    | `Bad_request of Terrat_api_installations.List_dirspaces.Responses.Bad_request.t
    ]
  [@@deriving show]
end

module Page = struct
  let parse_link s =
    let open CCOption.Infix in
    CCString.Split.left ~by:"; " s
    >>= fun (link, rel) ->
    let uri = Uri.of_string (String.sub link 1 (String.length link - 2)) in
    CCString.Split.left ~by:"=" rel
    >>= function
    | "rel", n ->
        let name = String.sub n 1 (String.length n - 2) in
        Some (name, uri)
    | _ -> None

  let rec parse_links s =
    if String.length s > 0 then
      let open CCOption.Infix in
      match CCString.Split.left ~by:", " s with
      | Some (left, right) ->
          parse_link left >>= fun link -> parse_links right >>= fun rest -> Some (link :: rest)
      | None -> parse_link s >>= fun link -> Some [ link ]
    else Some []

  let of_response resp elts =
    let headers = Openapi.Response.headers resp in
    match CCList.Assoc.get ~eq:CCString.equal "link" headers with
    | Some link -> (
        match parse_links link with
        | Some links ->
            let next =
              CCOption.flat_map
                (CCFun.flip Uri.get_query_param' "page")
                (CCList.Assoc.get ~eq:CCString.equal "next" links)
            in
            let prev =
              CCOption.flat_map
                (CCFun.flip Uri.get_query_param' "page")
                (CCList.Assoc.get ~eq:CCString.equal "prev" links)
            in
            Brtl_js2_page.Page.make ?next ?prev elts
        | None ->
            Brtl_js2.Brr.Console.(log [ Jstr.v "Could not parse links"; Jstr.v link ]);
            Brtl_js2_page.Page.make elts)
    | None -> Brtl_js2_page.Page.make elts
end

module Tier = struct
  type t = { num_users_per_month : int option }
end

module type S = sig
  type t

  val create : unit -> (t, [> create_err ]) result Abb_js.Future.t

  module Comp : sig
    module Login : sig
      type config

      val is_enabled : Terrat_api_components.Server_config.t -> config option
      val run : config -> t Brtl_js2.Comp.t
    end

    module No_installations : sig
      val run : t Brtl_js2.Comp.t
    end

    module Add_installation : sig
      val run : t Brtl_js2.Comp.t
    end

    module Quickstart : sig
      val run : t Brtl_js2.Comp.t
    end
  end

  module User : sig
    type t

    val avatar_url : t -> string
  end

  module Server_config : sig
    type t

    val vcs_web_base_url : t -> string
  end

  module Installation : sig
    type t [@@deriving eq]

    val id : t -> string
    val name : t -> string
    val tier_name : t -> string
    val tier_features : t -> Tier.t
    val trial_ends_at : t -> Brtl_js2_datetime.t option
  end

  module Api : sig
    val whoami : t -> (User.t, [> Api.api_err ]) result Abb_js.Future.t
    val server_config : t -> (Server_config.t, [> Api.api_err ]) result Abb_js.Future.t
    val installations : t -> (Installation.t list, [> Api.api_err ]) result Abb_js.Future.t

    val work_manifests :
      ?tz:string ->
      ?page:string list ->
      ?limit:int ->
      ?q:string ->
      ?dir:[ `Asc | `Desc ] ->
      installation_id:string ->
      t ->
      ( Terrat_api_components.Installation_work_manifest.t Brtl_js2_page.Page.t,
        [> Api.work_manifests_err ] )
      result
      Abb_js.Future.t

    val work_manifest_outputs :
      ?tz:string ->
      ?page:string list ->
      ?limit:int ->
      ?q:string ->
      ?lite:bool ->
      installation_id:string ->
      work_manifest_id:string ->
      t ->
      ( Terrat_api_components.Installation_workflow_step_output.t Brtl_js2_page.Page.t,
        [> Api.work_manifest_outputs_err ] )
      result
      Abb_js.Future.t

    val dirspaces :
      ?tz:string ->
      ?page:string list ->
      ?limit:int ->
      ?q:string ->
      ?dir:[ `Asc | `Desc ] ->
      installation_id:string ->
      t ->
      ( Terrat_api_components.Installation_dirspace.t Brtl_js2_page.Page.t,
        [> Api.dirspaces_err ] )
      result
      Abb_js.Future.t

    val repos :
      ?page:string list ->
      installation_id:string ->
      t ->
      (Terrat_api_components.Installation_repo.t Brtl_js2_page.Page.t, [> Api.api_err ]) result
      Abb_js.Future.t

    val repos_refresh :
      installation_id:string -> t -> (string option, [> Api.api_err ]) result Abb_js.Future.t

    val task :
      id:string -> t -> (Terrat_api_components.Task.t, [> Api.api_err ]) result Abb_js.Future.t
  end
end
