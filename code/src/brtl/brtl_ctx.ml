module Request = Cohttp.Request

type ('a, 'b) t = {
  request : Request.t;
  metadata : Hmap.t;
  body : 'a;
  response : 'b;
  remote_addr : string;
  token : string;
}

let create remote_addr request =
  {
    request;
    metadata = Hmap.empty;
    body = ();
    response = ();
    remote_addr;
    token = Ouuid.(to_string ~upper:false (v4 ()));
  }

let uri t =
  let uri = Request.uri t.request in
  match Uri.scheme uri with
  | Some _ -> uri
  | None ->
      Uri.with_scheme
        uri
        (Some
           (CCOption.get_or
              ~default:"http"
              (Cohttp.Header.get (Request.headers t.request) "x-forwarded-proto")))

let uri_base t =
  let forwarded_base =
    t.request
    |> Request.headers
    |> CCFun.flip Cohttp.Header.get "x-forwarded-base"
    (* Remove any trailing slashes *)
    |> CCOption.map CCFun.(CCString.rdrop_while (( = ) '/') %> Uri.of_string)
  in
  CCOption.get_lazy (fun () -> Uri.with_path (uri t) "/") forwarded_base

let request t = t.request
let md_find key t = Hmap.find key t.metadata
let md_add key v t = { t with metadata = Hmap.add key v t.metadata }
let md_rem key t = { t with metadata = Hmap.rem key t.metadata }
let body t = t.body
let set_body b t = { t with body = b }
let response t = t.response
let set_response r t = { t with response = r }
let remote_addr t = t.remote_addr
let token t = t.token
