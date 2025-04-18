module Method = struct
  type t =
    [ `GET
    | `PUT
    | `POST
    | `DELETE
    ]

  let string_of_t = function
    | `GET -> "GET"
    | `PUT -> "PUT"
    | `POST -> "POST"
    | `DELETE -> "DELETE"
end

module Response = struct
  type t = {
    status : int;
    text : string;
  }

  let text t = t.text
  let status t = t.status
end

let send ?(headers = []) ?body ~meth ~url () =
  let open Js_of_ocaml in
  let meth = Method.string_of_t meth in
  let req = XmlHttpRequest.create () in
  let promise =
    Abb_fut_js.Promise.create
      ~abort:(fun () ->
        req##abort;
        Abb_fut_js.return ())
      ()
  in
  req##.onload :=
    Dom.handler (fun _ ->
        (* TODO: Verify this responseText behaviour is correct *)
        let response =
          Response.
            {
              status = req##.status;
              text = Js.to_string (Js.Opt.get req##.responseText (fun () -> Js.string ""));
            }
        in
        Abb_fut_js.run (Abb_fut_js.Promise.set promise (Ok response));
        Js._true);
  req##.onerror :=
    Dom.handler (fun _ ->
        Abb_fut_js.run (Abb_fut_js.Promise.set promise (Error `Error));
        Js._true);
  req##_open (Js.string meth) (Js.string url) Js._true;
  List.iter (fun (h, s) -> req##setRequestHeader (Js.string h) (Js.string s)) headers;
  req##send (Js.Opt.map (Js.Opt.option body) Js.string);
  Abb_fut_js.Promise.future promise
