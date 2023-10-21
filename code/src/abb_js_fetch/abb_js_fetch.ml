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
    headers : (string * string) list;
  }

  let text t = t.text
  let status t = t.status
  let headers t = t.headers
end

let fetch ?(headers = []) ?body ~meth ~url () =
  let module F = Brr_io.Fetch in
  let abort = Brr.Abort.controller () in
  let fut =
    F.url
      ~init:
        (F.Request.init
           ?body:(CCOption.map CCFun.(Jstr.v %> F.Body.of_jstr) body)
           ~headers:(F.Headers.of_assoc (CCList.map (fun (k, v) -> (Jstr.v k, Jstr.v v)) headers))
           ~method':(Jstr.v (Method.string_of_t meth))
           ~signal:(Brr.Abort.signal abort)
           ())
      (Jstr.v url)
  in
  let promise =
    Abb_fut_js.Promise.create
      ~abort:(fun () ->
        Brr.Abort.abort abort;
        Abb_fut_js.return ())
      ()
  in
  Fut.await fut (function
      | Ok resp ->
          let body = F.Response.as_body resp in
          Fut.await (F.Body.text body) (function
              | Ok text ->
                  Abb_fut_js.run
                    (Abb_fut_js.Promise.set
                       promise
                       (Ok
                          {
                            Response.status = F.Response.status resp;
                            text = Jstr.to_string text;
                            headers =
                              F.Headers.fold
                                (fun k v acc ->
                                  (CCString.lowercase_ascii (Jstr.to_string k), Jstr.to_string v)
                                  :: acc)
                                (F.Response.headers resp)
                                [];
                          }))
              | Error err -> Abb_fut_js.run (Abb_fut_js.Promise.set promise (Error (`Js_err err))))
      | Error err -> Abb_fut_js.run (Abb_fut_js.Promise.set promise (Error (`Js_err err))));
  Abb_fut_js.Promise.future promise
