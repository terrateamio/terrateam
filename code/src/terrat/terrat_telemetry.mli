module Event : sig
  type t =
    | Start of { github_app_id : string }
    | Run of {
        github_app_id : string;
        run_type : Terrat_work_manifest.Run_type.t;
        owner : string;
        repo : string;
      }
    | Ping of { github_app_id : string }
end

val send : Terrat_config.Telemetry.t -> Event.t -> unit Abb.Future.t
val start_ping_loop : Terrat_config.t -> unit Abb.Future.t
