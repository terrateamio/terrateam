open Js_of_ocaml

type 'a t = {
  signal : 'a Brtl_js.React.signal;
  set : ?step:Brtl_js.React.step -> 'a -> unit;
}

module Validator = struct
  type 'a v =
    [ `Ok of 'a
    | `Unset
    | `Invalid
    ]

  type ('a, 'b) t = {
    encode : 'a -> 'b option;
    decode : 'b -> 'a;
  }

  let create encode decode = { encode; decode }

  let ( %> ) a b =
    create (fun v -> CCOpt.(a.encode v >>= b.encode)) (fun v -> a.decode (b.decode v))

  let int = create CCInt.of_string CCInt.to_string

  let min_int v =
    create
      (function
        | value when value >= v -> Some value
        | _ -> None)
      CCFun.id

  let max_int v =
    create
      (function
        | value when value <= v -> Some value
        | _ -> None)
      CCFun.id

  let float fmt = create CCFloat.of_string_opt (Printf.sprintf fmt)

  let min_float v =
    create
      (function
        | value when value >= v -> Some value
        | _ -> None)
      CCFun.id

  let max_float v =
    create
      (function
        | value when value <= v -> Some value
        | _ -> None)
      CCFun.id

  let optional t =
    create
      (function
        | "" -> Some None
        | v -> (
            match t.encode v with
            | Some r -> Some (Some r)
            | None -> None))
      (function
        | None -> ""
        | Some v -> t.decode v)

  let required =
    create
      (function
        | "" -> None
        | v -> Some v)
      CCFun.id

  let to_option = function
    | `Ok v -> Some v
    | _ -> None
end

module React = struct
  let select ?(a = []) ?(value = "") ~options () =
    let elem_value, elem_set_value = Brtl_js.React.S.create value in
    let onchange =
      Brtl_js.handler_sync (fun event ->
          Js.Opt.iter event##.target (fun target ->
              Js.Opt.iter (Dom_html.CoerceTo.select target) (fun inp ->
                  elem_set_value (Js.to_string inp##.value))))
    in
    let options_rlist =
      Brtl_js.Rlist.map
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
    let elem = Brtl_js.Rhtml.select ~a:(Brtl_js.Html.a_onchange onchange :: a) options_rlist in
    ({ signal = elem_value; set = elem_set_value }, elem)

  let combobox ?(a = []) ?(value = "") ~options () =
    let datalist_id = Uuidm.(to_string (create `V4)) in
    let elem_value, elem_set_value = Brtl_js.React.S.create value in
    let onchange =
      Brtl_js.handler_sync (fun event ->
          Js.Opt.iter event##.target (fun target ->
              Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                  elem_set_value (Js.to_string inp##.value))))
    in
    let elem =
      Brtl_js.Html.input
        ~a:
          (Brtl_js.Html.a_value value
          :: Brtl_js.Html.a_onchange onchange
          :: Brtl_js.Html.a_oninput onchange
          :: Brtl_js.Html.a_list datalist_id
          :: a)
        ()
    in
    let datalist =
      Brtl_js.Rhtml.datalist
        ~a:[ Brtl_js.Html.a_id datalist_id ]
        ~children:
          (`Options
            (Brtl_js.Rlist.map
               (fun item ->
                 Brtl_js.Html.option ~a:[ Brtl_js.Html.a_value item ] (Brtl_js.Html.txt ""))
               options))
        ()
    in
    let set_value ?step s =
      let elem = Brtl_js.To_dom.of_input elem in
      elem##.value := Js.string s;
      elem_set_value ?step s
    in
    ({ signal = elem_value; set = set_value }, elem, datalist)
end

module Radio_gen = struct
  type 'a t = {
    name : string;
    signal_ : 'a Brtl_js.React.signal;
    set_ : ?step:Brtl_js.React.step -> 'a -> unit;
    mutable buttons : ('a * Html_types.input Brtl_js.Html.elt) list;
  }

  let signal t = t.signal_

  let set ?step t v =
    CCList.iter
      (fun (v', elem) ->
        let elem = Brtl_js.To_dom.of_input elem in
        elem##.checked := Js.bool (v = v'))
      t.buttons;
    t.set_ ?step v
end

let create signal set = { signal; set }
let signal t = t.signal
let get t = Brtl_js.React.S.value (signal t)
let set ?step t v = t.set ?step v

let valid_input ?(af = fun _ -> []) ?(value = `Unset) ~valid () =
  let elem_value, elem_set_value = Brtl_js.React.S.create value in
  let blurred, set_blurred = Brtl_js.React.S.create false in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value
                  (match valid.Validator.encode (Js.to_string inp##.value) with
                  | Some v -> `Ok v
                  | None -> `Invalid))))
  in
  let elem =
    Brtl_js.Html.input
      ~a:
        (Brtl_js.Html.a_value
           (match value with
           | `Ok v -> valid.Validator.decode v
           | _ -> "")
        :: Brtl_js.Html.a_onchange onchange
        :: Brtl_js.Html.a_oninput onchange
        :: (Brtl_js.Html.a_onblur @@ Brtl_js.handler_sync (fun _ -> set_blurred true))
        :: (af
           @@ Brtl_js.React.S.l2
                (fun v blurred ->
                  (* Only mark as validated or not if it has been modified *)
                  (not blurred) || v <> `Invalid)
                elem_value
                blurred))
      ()
  in
  let set_value ?step s =
    let elem = Brtl_js.To_dom.of_input elem in
    (match s with
    | `Ok v -> elem##.value := Js.string (valid.Validator.decode v)
    | `Unset ->
        set_blurred false;
        elem##.value := Js.string ""
    | `Invalid -> set_blurred true);
    elem_set_value ?step s
  in
  ({ signal = elem_value; set = set_value }, elem)

let input ?(a = []) ?(value = "") () =
  let elem_value, elem_set_value = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (Js.to_string inp##.value))))
  in
  let elem =
    Brtl_js.Html.input
      ~a:
        (Brtl_js.Html.a_value value
        :: Brtl_js.Html.a_onchange onchange
        :: Brtl_js.Html.a_oninput onchange
        :: a)
      ()
  in
  let set_value ?step s =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.value := Js.string s;
    elem_set_value ?step s
  in
  ({ signal = elem_value; set = set_value }, elem)

let textarea ?(a = []) ?(value = "") () =
  let elem_value, elem_set_value = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.textarea target) (fun inp ->
                elem_set_value (Js.to_string inp##.value))))
  in
  let elem =
    Brtl_js.Html.textarea
      ~a:(Brtl_js.Html.a_onchange onchange :: Brtl_js.Html.a_oninput onchange :: a)
      (Brtl_js.Html.txt value)
  in
  let set_value ?step s =
    let elem = Brtl_js.To_dom.of_textarea elem in
    elem##.value := Js.string s;
    elem_set_value ?step s
  in
  ({ signal = elem_value; set = set_value }, elem)

let checkbox ?(a = []) ?(value = false) () =
  let elem_value, elem_set_value = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (Js.to_bool inp##.checked))))
  in
  let a =
    if value then Brtl_js.Html.a_checked () :: Brtl_js.Html.a_onchange onchange :: a
    else Brtl_js.Html.a_onchange onchange :: a
  in
  let elem = Brtl_js.Html.input ~a:(Brtl_js.Html.a_input_type `Checkbox :: a) () in
  let set_value ?step b =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.checked := Js.bool b;
    elem_set_value ?step b
  in
  ({ signal = elem_value; set = set_value }, elem)

let radio ?(a = []) ~select_value radio_gen =
  let onchange = Brtl_js.handler_sync (fun _ -> Radio_gen.set radio_gen select_value) in
  let elem =
    Brtl_js.Html.input
      ~a:
        (Brtl_js.Html.a_input_type `Radio
        :: Brtl_js.Html.a_name radio_gen.Radio_gen.name
        :: Brtl_js.Html.a_onchange onchange
        :: a)
      ()
  in
  radio_gen.Radio_gen.buttons <- (select_value, elem) :: radio_gen.Radio_gen.buttons;
  elem

let radio_gen ?(a = []) ~value name =
  let signal_, set_ = Brtl_js.React.S.create value in
  let gen = Radio_gen.{ name; buttons = []; signal_; set_ } in
  let elem = radio ~a ~select_value:value gen in
  (Brtl_js.To_dom.of_input elem)##.checked := Js._true;
  (gen, elem)

let range ?(a = []) ?(value = 0) () =
  let elem_value, elem_set_value = Brtl_js.React.S.create value in
  let onchange =
    Brtl_js.handler_sync (fun event ->
        Js.Opt.iter event##.target (fun target ->
            Js.Opt.iter (Dom_html.CoerceTo.input target) (fun inp ->
                elem_set_value (int_of_string (Js.to_string inp##.value)))))
  in
  let elem =
    Brtl_js.Html.input
      ~a:
        (Brtl_js.Html.a_input_type `Range
        :: Brtl_js.Html.a_value (CCInt.to_string value)
        :: Brtl_js.Html.a_onchange onchange
        :: a)
      ()
  in
  let set_value ?step v =
    let elem = Brtl_js.To_dom.of_input elem in
    elem##.value := Js.string (CCInt.to_string v);
    elem_set_value ?step v
  in
  ({ signal = elem_value; set = set_value }, elem)

let select ?a ?value ~options () =
  let options, _ = Brtl_js.Rlist.create options in
  React.select ?a ?value ~options ()
