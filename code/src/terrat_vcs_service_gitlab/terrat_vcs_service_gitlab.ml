let src = Logs.Src.create "vcs_service_gitlab"

module Logs = (val Logs.src_log src : Logs.LOG)

module type ROUTES = sig
  type config

  val routes :
    config ->
    Terrat_storage.t ->
    (Brtl_rtng.Method.t * Brtl_rtng.Handler.t Brtl_rtng.Route.Route.t) list
end

module Make
    (Provider :
      Terrat_vcs_provider2_gitlab.S
        with type Api.Config.t = Terrat_vcs_service_gitlab_provider.Api.Config.t)
    (Routes : ROUTES with type config = Provider.Api.Config.t) =
struct
  module Routes = struct
    module Rt = struct
      let api () = Brtl_rtng.Route.(rel / "api")
      let api_v1 () = Brtl_rtng.Route.(api () / "v1")
      let gitlab () = Brtl_rtng.Route.(api () / "gitlab")
      let gitlab_v1 () = Brtl_rtng.Route.(gitlab () / "v1")

      let gitlab_callback () =
        Brtl_rtng.Route.(
          api_v1 () / "gitlab" / "callback" /? Query.string "code" /? Query.string "state")
    end

    let routes config storage =
      Routes.routes config storage
      @ Brtl_rtng.Route.
          [
            ( `GET,
              Rt.gitlab_callback () --> Terrat_vcs_service_gitlab_ep_callback.get config storage );
          ]
  end

  module Service = struct
    type t = {
      config : Provider.Api.Config.t;
      storage : Terrat_storage.t;
    }

    type vcs_config = Provider.Api.Config.vcs_config

    let name _ = "gitlab"

    let start config vcs_config storage =
      let config = Provider.Api.Config.make ~config ~vcs_config () in
      Abb.Future.return { config; storage }

    let stop t = raise (Failure "nyi")
    let routes t = Routes.routes t.config t.storage
    let get_user t user_id = Abb.Future.return (Ok None)
  end
end
