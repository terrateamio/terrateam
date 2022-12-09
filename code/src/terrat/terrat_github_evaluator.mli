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
        tag_query : Terrat_tag_set.t;
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
        tag_query:Terrat_tag_set.t ->
        user:string ->
        t

      val request_id : t -> string
    end
  end
end

module Event : sig
  val eval : Terrat_storage.t -> S.Event.T.t -> unit Abb.Future.t
end

module Runner : sig
  val run : request_id:string -> Terrat_config.t -> Terrat_storage.t -> unit Abb.Future.t
end
