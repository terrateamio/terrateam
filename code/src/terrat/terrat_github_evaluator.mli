module S : sig
  module Event : sig
    module T : sig
      type t = {
        access_token : string;
        config : Terrat_config.t;
        installation_id : int;
        pull_number : int;
        repository : Terrat_github_webhooks.Repository.t;
        request_id : string;
        event_type : Terrat_evaluator.Event.Event_type.t;
        tag_query : Terrat_tag_query.t;
        user : string;
      }

      val make :
        access_token:string ->
        config:Terrat_config.t ->
        installation_id:int ->
        pull_number:int ->
        repository:Terrat_github_webhooks.Repository.t ->
        request_id:string ->
        event_type:Terrat_evaluator.Event.Event_type.t ->
        tag_query:Terrat_tag_query.t ->
        user:string ->
        t

      val request_id : t -> string
    end
  end
end

module Event : sig
  val eval : Terrat_storage.t -> S.Event.T.t -> unit Abb.Future.t
end

module Drift : sig
  module Service : sig
    val run : Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
  end
end

module Runner : sig
  val run : request_id:string -> Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
end

module Work_manifest : sig
  val initiate :
    request_id:string ->
    Terrat_config.t ->
    Terrat_storage.t ->
    Uuidm.t ->
    Terrat_api_components.Work_manifest_initiate.t ->
    Terrat_api_components.Work_manifest.t option Abb.Future.t

  val plan_fetch :
    request_id:string ->
    path:string ->
    workspace:string ->
    Terrat_storage.t ->
    Uuidm.t ->
    (string option, [> `Error ]) result Abb.Future.t

  val plan_store :
    request_id:string ->
    path:string ->
    workspace:string ->
    has_changes:bool ->
    Terrat_storage.t ->
    Uuidm.t ->
    string ->
    (unit, [> `Error ]) result Abb.Future.t

  val results_store :
    request_id:string ->
    Terrat_config.t ->
    Terrat_storage.t ->
    Uuidm.t ->
    Terrat_api_work_manifest.Results.Request_body.t ->
    (unit, [> `Error ]) result Abb.Future.t
end

module Push : sig
  val eval :
    request_id:string ->
    installation_id:int ->
    owner:string ->
    name:string ->
    default_branch:string ->
    Terrat_config.t ->
    Terrat_storage.t ->
    unit Abb.Future.t
end
