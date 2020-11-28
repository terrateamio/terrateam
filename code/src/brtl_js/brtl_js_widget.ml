open Js_of_ocaml

let input ?(a = []) ?(value = "") () =
  let (elem_value, elem_set_value) = Brtl_js.React.S.create value in
  let onkeyup =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (Js.to_string inp##.value))))
  in
  let elem =
    Brtl_js.Html.input ~a:(Brtl_js.Html.a_value value :: Brtl_js.Html.a_onkeyup onkeyup :: a) ()
  in
  let set_value ?step s =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.value := Js.string s;
    elem_set_value ?step s
  in
  (elem_value, set_value, elem)
