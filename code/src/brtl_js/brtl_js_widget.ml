open Js_of_ocaml

type 'a t = {
  signal : 'a Brtl_js.React.signal;
  set : ?step:Brtl_js.React.step -> 'a -> unit;
}

let signal t = t.signal

let set ?step t v = t.set ?step v

let input ?(a = []) ?(value = "") () =
  let (elem_value, elem_set_value) = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (Js.to_string inp##.value))))
  in
  let elem =
    Brtl_js.Html.input
      ~a:
        ( Brtl_js.Html.a_value value
        :: Brtl_js.Html.a_onchange onchange
        :: Brtl_js.Html.a_oninput onchange
        :: a )
      ()
  in
  let set_value ?step s =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.value := Js.string s;
    elem_set_value ?step s
  in
  ({ signal = elem_value; set = set_value }, elem)

let checkbox ?(a = []) ?(value = false) () =
  let (elem_value, elem_set_value) = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (Js.to_bool inp##.checked))))
  in
  let a =
    if value then
      Brtl_js.Html.a_checked () :: Brtl_js.Html.a_onchange onchange :: a
    else
      Brtl_js.Html.a_onchange onchange :: a
  in
  let elem = Brtl_js.Html.input ~a:(Brtl_js.Html.a_input_type `Checkbox :: a) () in
  let set_value ?step b =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.checked := Js.bool b;
    elem_set_value ?step b
  in
  ({ signal = elem_value; set = set_value }, elem)

let range ?(a = []) ?(value = 0) () =
  let (elem_value, elem_set_value) = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (int_of_string (Js.to_string inp##.value)))))
  in
  let elem =
    Brtl_js.Html.input
      ~a:
        ( Brtl_js.Html.a_input_type `Range
        :: Brtl_js.Html.a_value (CCInt.to_string value)
        :: Brtl_js.Html.a_onchange onchange
        :: a )
      ()
  in
  let set_value ?step v =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.value := Js.string (CCInt.to_string v);
    elem_set_value ?step v
  in
  ({ signal = elem_value; set = set_value }, elem)

let select ?(a = []) ?(value = "") ~options () =
  let (elem_value, elem_set_value) = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.select target) (fun inp ->
                elem_set_value (Js.to_string inp##.value))))
  in
  let elem =
    Brtl_js.Html.select ~a:(Brtl_js.Html.a_onchange onchange :: a)
    @@ CCList.map
         (fun (value, label) ->
           Brtl_js.Html.option
             ~a:
               [
                 Brtl_js.Html.a_value value;
                 Brtl_js.filter_attrib (Brtl_js.Html.a_selected ())
                 @@ Brtl_js.React.S.map (( = ) value) elem_value;
               ]
             (Brtl_js.Html.txt label))
         options
  in
  ({ signal = elem_value; set = elem_set_value }, elem)