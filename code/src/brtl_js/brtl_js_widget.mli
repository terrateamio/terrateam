val input :
  ?a:Html_types.input_attrib Brtl_js.Html.attrib list ->
  ?value:string ->
  unit ->
  string Brtl_js.React.signal
  * (?step:Brtl_js.React.step -> string -> unit)
  * [> Html_types.input ] Brtl_js.Html.elt
