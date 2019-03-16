module Method = struct
  type t = [ `GET
           | `POST
           | `DELETE
           ]

  let string_of_t = function
    | `GET -> "GET"
    | `POST -> "POST"
    | `DELETE -> "DELETE"
end

module Response = struct
  type t = { status : int
           ; text : string
           }
end

let state = Abb_fut.State.create ()

let send ?body ~meth ~url () =
  let open Js_of_ocaml in
  let meth = Method.string_of_t meth in
  let req = XmlHttpRequest.create () in
  let promise =
    Abb_fut.Promise.create
      ~abort:(fun () -> req##abort; Abb_fut.return ())
      ()
  in
  req##.onload := Dom.handler
      (fun _ ->
         let response = Response.({ status = req##.status
                                  ; text = Js.to_string req##.responseText
                                  })
         in
         ignore
           (Abb_fut.run_with_state
              (Abb_fut.Promise.set promise (Ok response))
              state);
         Js._true);
  req##.onerror := Dom.handler
      (fun _ ->
         ignore
           (Abb_fut.run_with_state
              (Abb_fut.Promise.set promise (Error `Error))
              state);
         Js._true);
  req##_open (Js.string meth) (Js.string url) Js._true;
  req##send (Js.Opt.map (Js.Opt.option body) Js.string);
  Abb_fut.Promise.future promise
