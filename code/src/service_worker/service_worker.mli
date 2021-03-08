module Blob : sig
  type t

  val slice : t -> start:int -> stop:int -> t

  val size : t -> int
end

module Headers : sig
  type t

  val create : t -> t

  val get : t -> string -> string option

  val set : t -> string -> string -> unit
end

module Request : sig
  type t

  val url : t -> string

  val meth : t -> string

  val headers : t -> Headers.t
end

module Response : sig
  type t

  val blob : t -> Blob.t Abb_js.Future.t

  val create : body:Blob.t -> headers:Headers.t -> status:int -> t

  val clone : t -> t

  val status : t -> int

  val headers : t -> Headers.t
end

module Background_fetch_registration : sig
  module Record : sig
    type t

    val id : t -> string

    val request : t -> Request.t

    val response_ready : t -> Response.t Abb_js.Future.t
  end

  type t

  val id : t -> string

  val upload_total : t -> int

  val uploaded : t -> int

  val download_total : t -> int

  val downloaded : t -> int

  val result : t -> [ `Active | `Failure of string | `Success ]

  val records_available : t -> bool

  val abort : t -> bool Abb_js.Future.t

  val match_all : t -> Record.t list Abb_js.Future.t

  val match_ : t -> Request.t -> Record.t option Abb_js.Future.t

  val set_onprogress : t -> (unit -> unit Abb_js.Future.t) -> unit

  val rem_onprogress : t -> unit
end

module Background_fetch_event : sig
  type t

  val wait_until : t -> unit Abb_js.Future.t -> unit

  val registration : t -> Background_fetch_registration.t

  val update_ui : t -> 'a
end

module Registration : sig
  module Icon_def : sig
    type t

    val create : ?typ:string -> sizes:string -> string -> t
  end

  module Options : sig
    type t

    val create : title:string -> icons:Icon_def.t list -> total_size:int -> t
  end

  type t

  val installing : t -> bool

  val background_fetch :
    t -> string -> string list -> Options.t -> Background_fetch_registration.t Abb_js.Future.t

  val background_fetch_ids : t -> string list Abb_js.Future.t

  val background_fetch_get : t -> string -> Background_fetch_registration.t option Abb_js.Future.t
end

module Service_worker_container : sig
  type t

  val register : t -> scope:string -> string -> Registration.t Abb_js.Future.t

  val ready : t -> Registration.t Abb_js.Future.t
end

module Cache : sig
  type t

  val add_all : t -> string list -> unit Abb_js.Future.t

  val put : t -> Request.t -> Response.t -> unit Abb_js.Future.t

  val delete : t -> string -> bool Abb_js.Future.t
end

module Cache_storage : sig
  type t

  val open_ : t -> string -> Cache.t Abb_js.Future.t

  val match_ : t -> Request.t -> Response.t Js_of_ocaml.Js.optdef Abb_js.Future.t

  val match_str : t -> string -> Response.t Js_of_ocaml.Js.optdef Abb_js.Future.t

  val keys : t -> string list Abb_js.Future.t

  val delete : t -> string -> unit Abb_js.Future.t
end

module Global_scope : sig
  module Event : sig
    type t

    val wait_until : t -> unit Abb_js.Future.t -> unit
  end

  module Install_event : sig
    type t

    val wait_until : t -> unit Abb_js.Future.t -> unit
  end

  module Fetch_event : sig
    type t

    val request : t -> Request.t

    val respond_with : t -> Response.t Abb_js.Future.t -> unit
  end

  module Clients : sig
    type t

    val claim : t -> unit Abb_js.Future.t
  end

  type t

  val self : t

  val caches : Cache_storage.t

  val clients : Clients.t

  val fetch : Request.t -> Response.t Abb_js.Future.t

  val skip_waiting : t -> unit

  val set_oninstall : t -> (Install_event.t -> unit) -> unit

  val set_onactivate : t -> (Event.t -> unit) -> unit

  val set_onfetch : t -> (Fetch_event.t -> unit) -> unit
end

module Event_name : sig
  type 'a t
end

val background_fetch_success : Background_fetch_event.t Event_name.t

val service_worker : unit -> Service_worker_container.t option

val add_event_listener : 'a Event_name.t -> ('a -> unit) -> unit
