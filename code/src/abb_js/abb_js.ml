open Js_of_ocaml
module Future = Abb_fut_js

let sleep duration =
  let timeout_id = ref None in
  let p =
    Future.Promise.create
      ~abort:(fun () ->
        CCOpt.iter Dom_html.clearTimeout !timeout_id;
        Future.return ())
      ()
  in
  let id =
    Dom_html.setTimeout (fun () -> Future.run (Future.Promise.set p ())) (duration *. 1000.0)
  in
  timeout_id := Some id;
  Future.Promise.future p
