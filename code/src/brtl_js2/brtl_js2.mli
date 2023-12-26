module Note : sig
  type 'a signal = 'a Note.signal
  type 'a event = 'a Note.event

  module Step : module type of Note.Step with type t = Note.Step.t

  module Logr : sig
    include module type of Note.Logr with type 'a obs = 'a Note.Logr.obs and type t = Note.Logr.t

    val destroy' : t option -> unit
  end

  module S : sig
    include module type of Note.S with type 'a t = 'a Note.S.t

    val create : eq:('a -> 'a -> bool) -> 'a -> 'a signal * 'a set
    val const : eq:('a -> 'a -> bool) -> 'a -> 'a signal
    val hold : eq:('a -> 'a -> bool) -> 'a -> 'a event -> 'a signal
    val map : eq:('b -> 'b -> bool) -> ('a -> 'b) -> 'a signal -> 'b signal
    val app : eq:('b -> 'b -> bool) -> ('a -> 'b) signal -> 'a signal -> 'b signal
    val accum : eq:('a -> 'a -> bool) -> 'a -> ('a -> 'a) event -> 'a signal
    val fix : eq:('a -> 'a -> bool) -> 'a -> ('a signal -> 'a signal * 'b) -> 'b
    val l1 : eq:('b -> 'b -> bool) -> ('a -> 'b) -> 'a signal -> 'b signal
    val l2 : eq:('c -> 'c -> bool) -> ('a -> 'b -> 'c) -> 'a signal -> 'b signal -> 'c signal

    val l3 :
      eq:('d -> 'd -> bool) ->
      ('a -> 'b -> 'c -> 'd) ->
      'a signal ->
      'b signal ->
      'c signal ->
      'd signal
  end

  module E : module type of Note.E with type 'a t = 'a Note.E.t
end

module Brr :
  module type of Brr
    with type El.t = Brr.El.t
     and type 'a Ev.t = 'a Brr.Ev.t
     and type At.t = Brr.At.t
     and type Navigator.t = Brr.Navigator.t

module Io : sig
  include module type of Brr_io

  module Clipboard : sig
    include module type of Brr_io.Clipboard

    val read : t -> (Item.t list, Jv.Error.t) result Abb_js.Future.t
    val read_text : t -> (Jstr.t, Jv.Error.t) result Abb_js.Future.t
    val write : t -> Item.t list -> (unit, Jv.Error.t) result Abb_js.Future.t
    val write_text : t -> Jstr.t -> (unit, Jv.Error.t) result Abb_js.Future.t
  end
end

module Kit : sig
  include module type of Note_brr_kit

  module Ui : sig
    include module type of Note_brr_kit.Ui

    module Value_selector : sig
      include module type of Note_brr_kit.Ui.Value_selector

      module Menu : sig
        include module type of Note_brr_kit.Ui.Value_selector.Menu

        val v' :
          ?class':Jstr.t ->
          ?enabled:bool Note.signal ->
          action:('a -> unit Abb_js.Future.t) ->
          ('a -> Jstr.t) ->
          'a list Note.signal ->
          'a Note.signal ->
          'a t
      end
    end

    module Button : sig
      include module type of Note_brr_kit.Ui.Button

      val v' :
        ?class':Jstr.t ->
        ?active:bool Note.signal ->
        ?enabled:bool Note.signal ->
        ?tip:Jstr.t Note.signal ->
        action:('a -> unit Abb_js.Future.t) ->
        Brr.El.t list Note.signal ->
        'a ->
        'a t
    end

    module Input : sig
      type t

      val v :
        ?class':Jstr.t ->
        ?enabled:bool Note.signal ->
        ?on:'a Note.event ->
        ?placeholder:Jstr.t ->
        Jstr.t Note.signal ->
        t

      val v' :
        ?class':Jstr.t ->
        ?enabled:bool Note.signal ->
        ?on:'a Note.event ->
        ?placeholder:Jstr.t ->
        action:(Jstr.t -> unit Abb_js.Future.t) ->
        Jstr.t Note.signal ->
        t

      val action : t -> Jstr.t Note.event
      val enabled : t -> bool Note.signal
      val editing : t -> bool Note.signal
      val value : t -> Jstr.t
      val el : t -> Brr.El.t
    end
  end
end

module R : sig
  include module type of Note_brr

  module Elr : sig
    include module type of Note_brr.Elr

    val on_add : (unit -> unit Abb_js.Future.t) -> Brr.El.t -> unit
    val on_rem : (unit -> unit Abb_js.Future.t) -> Brr.El.t -> unit

    (** Add an [on_add] handler to an element and return the element *)
    val with_add : (unit -> unit Abb_js.Future.t) -> Brr.El.t -> Brr.El.t

    (** Add an [on_rem] handler to an element and return the element *)
    val with_rem : (unit -> unit Abb_js.Future.t) -> Brr.El.t -> Brr.El.t
  end
end

module Router : sig
  type t

  val uri : t -> Uri.t Note.S.t

  (** Navigate to the [path] given.  Specify [base] if a different base URI
      should be used. *)
  val navigate : ?base:string -> t -> string -> unit
end

module State : sig
  type 'a t

  val router : 'a t -> Router.t
  val consumed_path : 'a t -> string
  val app_visibility : 'a t -> [ `Visible | `Hidden ] Note.S.t
  val app_state : 'a t -> 'a
  val with_app_state : 'b -> 'a t -> 'b t
end

module Output : sig
  type t

  val render : ?cleanup:(unit -> unit Abb_js.Future.t) -> Brr.El.t list Note.S.t -> t

  (** Same as [render ?cleanup (Note.S.const ~eq:(==) els)]. *)
  val const : ?cleanup:(unit -> unit Abb_js.Future.t) -> Brr.El.t list -> t

  (** Navigate to a path inside the same application *)
  val redirect : string -> t

  (** Navigate to a complete URI.  If the URI is incomplete, the app will crash
      and a message will be displayed in the console.*)
  val navigate : Uri.t -> t
end

(** A component is a function that takes a state and returns a signal
    representing an output. *)
module Comp : sig
  type 'a t = 'a State.t -> Output.t Abb_js.Future.t
end

module Router_output : sig
  val create : 'a State.t -> Brr.El.t -> 'a Comp.t Brtl_js2_rtng.Route.t list -> Brr.El.t

  val create' :
    wrap:('a -> 'b Comp.t) -> 'b State.t -> Brr.El.t -> 'a Brtl_js2_rtng.Route.t list -> Brr.El.t

  val const : 'a State.t -> Brr.El.t -> 'a Comp.t -> Brr.El.t
end

(** A placeholder.  When rendering a component, this allows specifying a
    placeholder that is replaced once the component is rendered. *)
module Ph : sig
  val create : Brr.El.t list -> 'a Comp.t -> 'a Comp.t
end

val main : 'a -> ('a State.t -> unit Abb_js.Future.t) -> unit
