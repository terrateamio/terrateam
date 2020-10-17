open Js_of_ocaml

let sleep duration =
  let timeout_id = ref None in
  let p =
    Abb_fut_js.Promise.create
      ~abort:(fun () ->
        CCOpt.iter Dom_html.clearTimeout !timeout_id;
        Abb_fut_js.return ())
      ()
  in
  let id =
    Dom_html.setTimeout (fun () -> Abb_fut_js.run (Abb_fut_js.Promise.set p ())) (duration *. 1000.0)
  in
  timeout_id := Some id;
  Abb_fut_js.Promise.future p
