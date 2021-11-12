module Radio_gen : sig
  type 'a t

  val signal : 'a t -> 'a Brtl_js.React.signal

  val set : ?step:Brtl_js.React.step -> 'a t -> 'a -> unit
end

type 'a t

module Validator : sig
  type 'a v =
    [ `Ok      of 'a
    | `Unset
    | `Invalid
    ]

  type ('a, 'b) t

  val create : ('a -> 'b option) -> ('b -> 'a) -> ('a, 'b) t

  val ( %> ) : ('a, 'b) t -> ('b, 'c) t -> ('a, 'c) t

  val int : (string, int) t

  val min_int : int -> (int, int) t

  val max_int : int -> (int, int) t

  val float : (float -> string, unit, string) format -> (string, float) t

  val min_float : float -> (float, float) t

  val max_float : float -> (float, float) t

  val optional : (string, 'b) t -> (string, 'b option) t

  val required : (string, string) t

  val to_option : 'a v -> 'a option
end

module React : sig
  val select :
    ?a:Html_types.select_attrib Brtl_js.Html.attrib list ->
    ?value:string ->
    options:(string * string) Brtl_js.Rlist.t ->
    unit ->
    string t * [> Html_types.select ] Brtl_js.Html.elt

  (** An input box combined with select *)
  val combobox :
    ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
    ?value:string ->
    options:string Brtl_js.Rlist.t ->
    unit ->
    string t * [> Html_types.input ] Brtl_js.Html.elt * [> Html_types.datalist ] Brtl_js.Rhtml.elt
end

val create : 'a Brtl_js.React.signal -> (?step:Brtl_js.React.step -> 'a -> unit) -> 'a t

val signal : 'a t -> 'a Brtl_js.React.signal

val get : 'a t -> 'a

val set : ?step:Brtl_js.React.step -> 'a t -> 'a -> unit

val valid_input :
  ?af:(bool Brtl_js.React.signal -> Html_types.input_attrib Brtl_js.Html.attrib list) ->
  ?value:'b Validator.v ->
  valid:(string, 'b) Validator.t ->
  unit ->
  'b Validator.v t * [> Html_types.input ] Brtl_js.Html.elt

val input :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:string ->
  unit ->
  string t * [> Html_types.input ] Brtl_js.Html.elt

val textarea :
  ?a:Html_types.textarea_attrib Brtl_js.Html.attrib list ->
  ?value:string ->
  unit ->
  string t * [> Html_types.textarea ] Brtl_js.Html.elt

val checkbox :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:bool ->
  unit ->
  bool t * [> Html_types.input ] Brtl_js.Html.elt

(** Create a radio button from a radio generator.  *)
val radio :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  select_value:'a ->
  'a Radio_gen.t ->
  [> Html_types.input ] Brtl_js.Html.elt

(** Create radio button generator.  This ensures that when one button is chosen
   all others are deselected.  Also returns a radio button that is selected. *)
val radio_gen :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  value:'a ->
  string ->
  'a Radio_gen.t * [> Html_types.input ] Brtl_js.Html.elt

val range :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:int ->
  unit ->
  int t * [> Html_types.input ] Brtl_js.Html.elt

(** Create a select.  Options are of the form (value * label) *)
val select :
  ?a:Html_types.select_attrib Brtl_js.Html.attrib list ->
  ?value:string ->
  options:(string * string) list ->
  unit ->
  string t * [> Html_types.select ] Brtl_js.Html.elt
