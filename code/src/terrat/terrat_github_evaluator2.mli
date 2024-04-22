module Pull_request : sig
  type stored
  type 'a t
end

module Drift : sig
  type t
end

module Index : sig
  type t
end

module Ref : sig
  type t

  val of_string : string -> t
end

module Repo : sig
  type t

  val make : id:int -> name:string -> owner:string -> unit -> t
  val id : t -> int
  val name : t -> string
  val owner : t -> string
end

module Event : sig
  module Initiate : sig
    type t

    val make :
      branch_ref:Ref.t ->
      config:Terrat_config.t ->
      encryption_key:Cstruct.t ->
      request_id:string ->
      run_id:string ->
      storage:Terrat_storage.t ->
      work_manifest_id:Uuidm.t ->
      unit ->
      t

    val eval : t -> (Terrat_api_components.Work_manifest.t, [> `Error ]) result Abb.Future.t
  end

  module Terraform : sig
    type t

    val make :
      config:Terrat_config.t ->
      installation_id:int ->
      operation:Terrat_evaluator2.Tf_operation.t ->
      pull_number:int ->
      repo:Repo.t ->
      request_id:string ->
      storage:Terrat_storage.t ->
      tag_query:Terrat_tag_query.t ->
      user:string ->
      unit ->
      t

    val eval :
      t ->
      ( (Pull_request.stored Pull_request.t, Drift.t, Index.t) Terrat_work_manifest2.Kind.t
        Terrat_work_manifest2.Existing.t
        list,
        [> `Error ] )
      result
      Abb.Future.t
  end

  module Repo_config : sig
    type t

    val make :
      config:Terrat_config.t ->
      installation_id:int ->
      pull_number:int ->
      repo:Repo.t ->
      request_id:string ->
      storage:Terrat_storage.t ->
      user:string ->
      unit ->
      t

    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Index : sig
    type t

    val make :
      config:Terrat_config.t ->
      installation_id:int ->
      pull_number:int ->
      repo:Repo.t ->
      request_id:string ->
      storage:Terrat_storage.t ->
      user:string ->
      unit ->
      t

    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Unlock : sig
    type t

    val make :
      access_token:string ->
      config:Terrat_config.t ->
      ids:Terrat_evaluator2.Unlock_id.t list ->
      installation_id:int ->
      pull_number:int ->
      repo:Repo.t ->
      request_id:string ->
      storage:Terrat_storage.t ->
      user:string ->
      unit ->
      t

    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Push : sig
    type t

    val make :
      branch:Ref.t ->
      config:Terrat_config.t ->
      installation_id:int ->
      repo:Repo.t ->
      request_id:string ->
      storage:Terrat_storage.t ->
      unit ->
      t

    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Drift : sig
    type t

    val make : config:Terrat_config.t -> request_id:string -> storage:Terrat_storage.t -> unit -> t
    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Plan_cleanup : sig
    type t

    val make : request_id:string -> storage:Terrat_storage.t -> unit -> t
    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Plan_get : sig
    type t

    val make :
      config:Terrat_config.t ->
      dir:string ->
      request_id:string ->
      storage:Terrat_storage.t ->
      work_manifest_id:Uuidm.t ->
      workspace:string ->
      unit ->
      t

    val eval : t -> (string option, [> `Error ]) result Abb.Future.t
  end

  module Plan_set : sig
    type t

    val make :
      config:Terrat_config.t ->
      data:string ->
      dir:string ->
      has_changes:bool ->
      request_id:string ->
      storage:Terrat_storage.t ->
      work_manifest_id:Uuidm.t ->
      workspace:string ->
      unit ->
      t

    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end

  module Result : sig
    type t

    val make :
      config:Terrat_config.t ->
      request_id:string ->
      result:Terrat_api_components.Work_manifest_result.t ->
      storage:Terrat_storage.t ->
      work_manifest_id:Uuidm.t ->
      unit ->
      t

    val eval : t -> (unit, [> `Error ]) result Abb.Future.t
  end
end

module Runner : sig
  type t

  val make : config:Terrat_config.t -> request_id:string -> storage:Terrat_storage.t -> unit -> t
  val eval : t -> (unit, [> `Error ]) result Abb.Future.t
end
