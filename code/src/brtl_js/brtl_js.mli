open Js_of_ocaml
module React = React
module Rhtml = Js_of_ocaml_tyxml.Tyxml_js.R.Html
module Rsvg = Js_of_ocaml_tyxml.Tyxml_js.R.Svg
module Rlist = ReactiveData.RList
module Html = Js_of_ocaml_tyxml.Tyxml_js.Html
module Svg = Js_of_ocaml_tyxml.Tyxml_js.Svg
module To_dom = Js_of_ocaml_tyxml.Tyxml_js.To_dom

module Router : sig
  type t

  val uri : t -> Uri.t React.signal

  val navigate : t -> Uri.t -> unit
end

module State : sig
  type t

  val router : t -> Router.t

  val consumed_path : t -> string
end

module Handler : sig
  type ret =
    [ `Render       of Html_types.div_content_fun Html.elt list
    | `With_cleanup of Html_types.div_content_fun Html.elt list * (State.t -> unit Abb_fut_js.t)
    | `Navigate     of Uri.t
    ]

  type t = State.t -> ret Abb_fut_js.t
end

module Router_output : sig
  val create :
    ?a:Html_types.div_attrib Html.attrib list ->
    State.t ->
    Handler.t Brtl_js_rtng.Route.t list ->
    [> Html_types.div ] Html.elt
end

val comp :
  ?a:Html_types.div_attrib Html.attrib list -> State.t -> Handler.t -> [> Html_types.div ] Html.elt

val dom_html_handler :
  ?continue:bool ->
  ((#Dom_html.event Js.t as 'b) -> unit Abb_fut_js.t) ->
  ('a, 'b) Dom_html.event_listener

val handler : ?continue:bool -> ('a -> unit Abb_fut_js.t) -> 'a -> bool

val handler_sync : ?continue:bool -> ('a -> unit) -> 'a -> bool

val select_by_id : string -> (Dom_html.element Js.t -> 'a Js.opt) -> 'a

val select_by_id_opt : string -> (Dom_html.element Js.t -> 'a Js.opt) -> 'a option

val scroll_into_view : ?block:string -> ?inline:string -> Dom_html.element Js.t -> unit

val replace_child : ?p:#Dom.node Js.t -> old:#Dom.node Js.t -> #Dom.node Js.t -> unit

val append_child : p:#Dom.node Js.t -> #Dom.node Js.t -> unit

val remove_child : p:#Dom.node Js.t -> #Dom.node Js.t -> unit

val filter_attrib : 'a Rhtml.attrib -> bool React.signal -> 'a Rhtml.attrib

val main : string -> (State.t -> Dom_html.divElement Js.t -> unit Abb_fut_js.t) -> unit
