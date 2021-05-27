module Title : sig
  type t =
    [ `Txt of string
    | `Elt of Html_types.div_content Brtl_js.Html.elt list
    ]
end

module Choice : sig
  type 'a t

  (** Create a choice which has a value (must match what a route will return),
     and a title that the user will see, and maps to a URI when clicked *)
  val create : value:'a -> title:Title.t -> Uri.t -> 'a t
end

(** Run nav bar component.  Given a nav choices, and a way to map the current
   URL to the choice.  [selected] and [unselected] correspond to the CSS
   classes. *)
val run :
  eq:('a -> 'a -> bool) ->
  nav_class:string ->
  selected:string ->
  unselected:string ->
  choices:'a Choice.t list ->
  'a Brtl_js_rtng.Route.t list ->
  Brtl_js.Handler.t
