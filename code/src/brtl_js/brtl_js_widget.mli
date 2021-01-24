type 'a t

val signal : 'a t -> 'a Brtl_js.React.signal

val set : ?step:Brtl_js.React.step -> 'a t -> 'a -> unit

val input :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:string ->
  unit ->
  string t * [> Html_types.input ] Brtl_js.Html.elt

val checkbox :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:bool ->
  unit ->
  bool t * [> Html_types.input ] Brtl_js.Html.elt

val range :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:int ->
  unit ->
  int t * [> Html_types.input ] Brtl_js.Html.elt
