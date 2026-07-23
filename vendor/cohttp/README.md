## ocaml-cohttp -- an OCaml library for HTTP clients and servers [![Main workflow](https://github.com/mirage/ocaml-cohttp/actions/workflows/workflow.yml/badge.svg)](https://github.com/mirage/ocaml-cohttp/actions/workflows/workflow.yml)

Cohttp is an OCaml library for creating HTTP daemons. It has a portable
HTTP parser, and implementations using various asynchronous programming
libraries:

* `Cohttp_lwt_unix` uses the [Lwt](https://ocsigen.org/lwt/) library, and
  specifically the UNIX bindings. It uses [ocaml-tls](https://github.com/mirleft/ocaml-tls)
  as the TLS implementation to handle HTTPS connections.
* `Cohttp_async` uses the [Async](https://realworldocaml.org/v1/en/html/concurrent-programming-with-async.html)
  library and `async_ssl` to handle HTTPS connections.
* `Cohttp_lwt` exposes an OS-independent Lwt interface, which is used
  by the [Mirage](https://mirage.io/) interface to generate standalone
  microkernels (use the cohttp-mirage subpackage).
* `Cohttp_lwt_jsoo` compiles to a JavaScript module that maps the Cohttp
  calls to XMLHTTPRequests.  This is used to compile OCaml libraries like
  the GitHub bindings to JavaScript and still run efficiently.

You can implement other targets using the parser very easily. Look at the `IO`
signature in `lib/s.mli` and implement that in the desired backend.

You can find help from cohttp users and maintainers at the
[discuss.ocaml.org](https://discuss.ocaml.org) forum or on the
[OCaml discord server](https://discord.gg/cCYQbqN).

## Table of contents

- [Installation](#installation)
- [Client Tutorial](#client-tutorial)
  * [Compile and execute with ocamlbuild](#compile-and-execute-with-ocamlbuild)
  * [Compile and execute with dune](#compile-and-execute-with-dune)
- [Dealing with timeouts](#dealing-with-timeouts)
- [Managing sessions](#managing-sessions)
- [Multipart form data](#multipart-form-data)
- [Creating custom resolver: a Docker Socket Client example](#creating-custom-resolver--a-docker-socket-client-example)
- [Dealing with redirects](#dealing-with-redirects)
- [Basic Server Tutorial](#basic-server-tutorial)
  * [Compile and execute with ocamlbuild](#compile-and-execute-with-ocamlbuild-1)
  * [Compile and execute with dune](#compile-and-execute-with-dune-1)
- [Installed Binaries](#installed-binaries)
- [Debugging](#debugging)
- [Important Links](#important-links)


## Installation

Latest stable version should be obtained from `opam`. Make sure to install the
specific backends you want as well. E.g.

```
$ opam install cohttp-lwt-unix cohttp-async
```

You can also obtain the development release:

```
$ opam pin add cohttp --dev-repo
```

## Client Tutorial

Cohttp provides clients for Async, Lwt, and Js_of_ocaml (Lwt based). In this tutorial,
we will use the lwt client but the example should be easily translatable to Async.

To create a simple request, use one of the methods in `Cohttp_lwt_unix.Client`.
`call` is the most general, there are also http method specialized such as
`get`, `post`, etc.

For example downloading the reddit frontpage:

```ocaml
open Lwt
open Cohttp
open Cohttp_lwt_unix

let body =
  Client.get (Uri.of_string "https://www.reddit.com/") >>= fun (resp, body) ->
  let code = resp |> Response.status |> Code.code_of_status in
  Printf.printf "Response code: %d\n" code;
  Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  Printf.printf "Body of length: %d\n" (String.length body);
  body

let () =
  let body = Lwt_main.run body in
  print_endline ("Received body\n" ^ body)
```

There are a few things to notice:

* We open 2 modules. `Cohttp` contains the backend independent modules and
  `Cohttp_lwt_unix` the lwt + unix specific ones.
* `Client.get` accepts a `Uri.t` and makes an http request. `Client.get` also
  accepts optional arguments for things like header information.
* The http response is returned in a tuple. The first element of the tuple
  contains the response's status code, headers, http version, etc. The second
  element contains the body.
* The body is then converted to a string and is returned (after the length is
  printed). Note that `Cohttp_lwt.Body.to_string` hence it's up to us to keep
  a reference to the result.
* We must trigger lwt's event loop for the request to run. `Lwt_main.run` will
  run the event loop and return with final value of `body` which we then print.

Note that `Cohttp_lwt_unix`/`Cohttp_async` are able to request an HTTPS page
by default. For `Cohttp_lwt_unix`, we use [ocaml-tls](https://github.com/mirleft/ocaml-tls.git)
(to use `lwt_ssl` is enough to use `Cohttp_lwt_unix_ssl` from the analogously
named package, the rest of the code does not change). For `Cohttp_async`, we use
`async_ssl` (but the user is able to use `ocaml-tls` with some modifications).

Consult the following modules for reference:

* [Cohttp_lwt.Client](https://github.com/mirage/ocaml-cohttp/blob/master/cohttp-lwt/src/s.ml)
* [Cohttp_async.Client](https://github.com/mirage/ocaml-cohttp/blob/master/cohttp-async/src/client.mli)

The full documentation for the latest published version of the library is
available on the [repository github pages](https://mirage.github.io/ocaml-cohttp/).

### Compile and execute with ocamlbuild

Build and execute with:

```
$ ocamlbuild -use-ocamlfind -tag thread -pkg cohttp-lwt-unix client_example.native
$ ./client_example.native
```

For manual builds, it is usually enough to remember that cohttp ships with 6
findlib (`ocamlfind`) libraries:

* `cohttp` - Base `Cohttp` module. No platform specific functionality
* `cohttp-async` - Async backend `Cohttp_async`
* `cohttp-lwt` - Lwt backend without unix specifics
* `cohttp-lwt-unix` - Unix based lwt backend
* `cohttp-lwt-jsoo` - Jsoo (XHR) client
* `cohttp-top` - Print cohttp types in the toplevel (`#require "cohttp-top"`)

### Compile and execute with dune

Create this `dune` file
```
cat - > dune <<EOF
(executable
  ; (public_name client_example)
  (name client_example)
  (libraries cohttp-lwt-unix))
EOF
```
then build and execute the example with
```
$ dune exec ./client_example.exe
```

## Dealing with timeouts

You can use [`Lwt.pick`](https://ocsigen.org/lwt/4.1.0/api/Lwt) to set a timeout
on the execution of a thread. For example, say that you want to set a timeout on
the `Client.get` thread in the example above, then you could modify the get call
as follows

```ocaml
let compute ~time ~f =
  Lwt.pick
    [
      (f () >|= fun v -> `Done v)
    ; (Lwt_unix.sleep time >|= fun () -> `Timeout)
    ]

let body =
  let get () = Client.get (Uri.of_string "https://www.reddit.com/") in
  compute ~time:0.1 ~f:get >>= function
  | `Timeout -> Lwt.fail_with "Timeout expired"
  | `Done (resp, body) -> Lwt.return (resp, body)
```

Executing the code, which you can actually try by calling
```
$ dune exec examples/lwt_unix_doc/client_lwt_timeout.exe
```
the call will most likely fail with the following output
```
Fatal error: exception (Failure "Timeout expired")
```

Similarly, in the case of `cohttp-async` you can directly use Async's
[`with_timeout`](https://ocaml.janestreet.com/ocaml-core/latest/doc/async_unix/Async_unix/Clock/index.html#val-with_timeout) function.
For example,

```ocaml
let get_body ~uri ~timeout =
    let%bind _, body = Cohttp_async.Client.get ~interrupt:(after (sec timeout)) uri in
    Body.to_string body    

let body =
  let uri = Uri.of_string "https://www.reddit.com/" in
  let timeout = 0.1 in
  Clock.with_timeout (sec timeout) (get_body ~uri ~timeout)
  >>| function
  | `Result body -> Log.debug logger "body: %s" body
  | `Timeout  -> Log.debug logger "Timeout with url:%s" url
```

## Managing sessions

Managing sessions and saving cookies across requests is not directly supported by
`cohttp`. It is not hard to roll out a custom solution, but an alternative is
to use the [`session`](https://github.com/inhabitedtype/ocaml-session) library,
which is compatible with `cohttp`.

## Multipart form data

Multipart form data is not supported out of the box but is provided by external libraries:
- [`multipart_form`](https://github.com/dinosaure/multipart_form) which has bounded memory consumption even when transferring large amount of data
- [`multipart-form-data`](https://github.com/cryptosense/multipart-form-data)
- [`http-multipart-formdata`](https://github.com/lemaetech/http-multipart-formdata) which however does not support streaming

## Creating custom resolver: a Docker Socket Client example

Cohttp provides a lot of utilities out of the box, but does not prevent the users
to dig in and customise it for their needs. The following is an example of a
[unix socket client to communicate with Docker](https://discuss.ocaml.org/t/how-to-write-a-simple-socket-based-web-client-for-docker/1760/3).

```ocaml
open Lwt.Infix
open Cohttp

let ctx =
  let resolver =
    let h = Hashtbl.create 1 in
    Hashtbl.add h "docker" (`Unix_domain_socket "/var/run/docker.sock");
    Resolver_lwt_unix.static h
  in
  Cohttp_lwt_unix.Client.custom_ctx ~resolver ()

let t =
  Cohttp_lwt_unix.Client.get ~ctx (Uri.of_string "http://docker/version")
  >>= fun (resp, body) ->
  let open Cohttp in
  let code = resp |> Response.status |> Code.code_of_status in
  Printf.printf "Response code: %d\n" code;
  Printf.printf "Headers: %s\n" (resp |> Response.headers |> Header.to_string);
  body |> Cohttp_lwt.Body.to_string >|= fun body ->
  Printf.printf "Body of length: %d\n" (String.length body);
  print_endline ("Received body\n" ^ body)

let _ = Lwt_main.run t
```

The main issue there is there no way to resolve a socket address, so you need to
create a custom resolver to map a hostname to the Unix domain socket.

To build and execute with `dune`, first create the following `dune` file
```
$ cat - > dune <<EOF
(executable
  ;(public_name docker_example)
  (name docker_example)
  (libraries cohttp-lwt-unix conduit-lwt))
EOF
```
then run the example with
```
$ dune exec ./docker_example.exe
```
Even though conduit is transitively there, for this example we are explicitly
mentioning it to emphasize that we are creating a new Conduit resolver. Refer to
[conduit's README](https://github.com/mirage/ocaml-conduit/) for examples of use and
links to up-to-date conduit documentation.

## Dealing with redirects

This examples has been adapted from a script on the [ocaml.org](https://github.com/ocaml/ocaml.org/blob/master/script/http.ml) website, and shows an explicit way to deal with redirects in `cohttp-lwt-unix`.

```ocaml
let rec http_get_and_follow ~max_redirects uri =
  let open Lwt.Syntax in
  let* ans = Cohttp_lwt_unix.Client.get uri in
  follow_redirect ~max_redirects uri ans

and follow_redirect ~max_redirects request_uri (response, body) =
  let open Lwt.Syntax in
  let status = Cohttp.Response.status response in
  (* The unconsumed body would otherwise leak memory *)
  let* () =
    if status <> `OK then Cohttp_lwt.Body.drain_body body else Lwt.return_unit
  in
  match status with
  | `OK -> Lwt.return (response, body)
  | `Permanent_redirect | `Moved_permanently ->
      handle_redirect ~permanent:true ~max_redirects request_uri response
  | `Found | `Temporary_redirect ->
      handle_redirect ~permanent:false ~max_redirects request_uri response
  | `Not_found | `Gone -> Lwt.fail_with "Not found"
  | status ->
      Lwt.fail_with
        (Printf.sprintf "Unhandled status: %s"
           (Cohttp.Code.string_of_status status))

and handle_redirect ~permanent ~max_redirects request_uri response =
  if max_redirects <= 0 then Lwt.fail_with "Too many redirects"
  else
    let headers = Cohttp.Response.headers response in
    let location = Cohttp.Header.get headers "location" in
    match location with
    | None -> Lwt.fail_with "Redirection without Location header"
    | Some url ->
        let open Lwt.Syntax in
        let uri = Uri.of_string url in
        let* () =
          if permanent then
            Logs.warn (fun m ->
                m "Permanent redirection from %s to %s"
                  (Uri.to_string request_uri)
                  url)
          else Lwt.return_unit
        in
        http_get_and_follow uri ~max_redirects:(max_redirects - 1)
```

The following example, adapted from [blue-http](https://github.com/brendanlong/blue-http/blob/master/src/redirect.ml), does a similar thing with `cohttp-async` (and [ppx_let](https://github.com/janestreet/ppx_let)).

```ocaml
open Core_kernel
open Async_kernel

let with_redirects ~max_redirects uri f =
  let seen_uris = Hash_set.create (module String) in
  let rec loop ~max_redirects uri =
    Hash_set.add seen_uris (Uri.to_string uri);
    let%bind ((response, response_body) as res) = f uri in
    let status_code =
      Cohttp.(Response.status response |> Code.code_of_status)
    in
    if Cohttp.Code.is_redirection status_code then (
      match Cohttp.(Response.headers response |> Header.get_location) with
      | Some new_uri when Uri.to_string new_uri |> Hash_set.mem seen_uris ->
          return res
      | Some new_uri ->
          if max_redirects > 0 then
            (* Cohttp leaks connections if we don't drain the response body *)
            Cohttp_async.Body.drain response_body >>= fun () ->
            loop ~max_redirects:(max_redirects - 1) new_uri
          else (
            Log.Global.debug ~tags:[]
              "Ignoring %d redirect from %s to %s: redirect limit exceeded"
              status_code (Uri.to_string uri) (Uri.to_string new_uri);
            return res)
      | None ->
          Log.Global.debug ~tags:[]
            "Ignoring %d redirect from %s: there is no Location header"
            status_code (Uri.to_string uri);
          return res)
    else return res
  in
  loop ~max_redirects uri
```

You can read a bit more on the rationale behind the absence of this functionality in the API [here](https://github.com/mirage/ocaml-cohttp/issues/76).

## Basic Server Tutorial

Implementing a server in cohttp using the Lwt backend (for Async is very similar)
is mostly equivalent to implementing a function of type :

```
conn -> Cohttp.Request.t -> Cohttp_lwt.Body.t -> (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t
```

The parameters are self explanatory but we'll summarize them quickly here:

* `conn` - contains connection information
* `Cohttp.Request.t` - Request information such as method, uri, headers, etc.
* `Cohttp_lwt.Body.t` - Contains the request body. You must manually decode the
  request body into json, form encoded pairs, etc. For cohttp, the body is
  simply binary data.

Here's an example of a simple cohttp server that outputs back request
information.

```ocaml
open Lwt
open Cohttp
open Cohttp_lwt_unix

let server =
  let callback _conn req body =
    let uri = req |> Request.uri |> Uri.to_string in
    let meth = req |> Request.meth |> Code.string_of_method in
    let headers = req |> Request.headers |> Header.to_string in
    ( body |> Cohttp_lwt.Body.to_string >|= fun body ->
      Printf.sprintf "Uri: %s\nMethod: %s\nHeaders\nHeaders: %s\nBody: %s" uri
        meth headers body )
    >>= fun body -> Server.respond_string ~status:`OK ~body ()
  in
  Server.create ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())
```

### Compile and execute with ocamlbuild

Build and execute with:
```
$ ocamlbuild -use-ocamlfind -tag thread -pkg cohttp-lwt-unix server_example.native
$ ./server_example.native
```

### Compile and execute with dune

Create this `dune` file
```
cat - > dune <<EOF
(executable
  ; (public_name server_example)
  (name server_example)
  (libraries cohttp-lwt-unix conduit-lwt))
EOF
```
then build and execute the example with
```
$ dune exec ./client_example.exe
```

As in the previous example, here we are explicitly mentioning conduit-lwt to
emphasize that we are relying on Conduit to specify the protocols and the
services. Refer to [conduit's README](https://github.com/mirage/ocaml-conduit/)
for examples of use and links to up-to-date conduit documentation.


## Installed Binaries

Cohttp comes with a few simple binaries that are handy, useful also to test cohttp
itself, and can serve as examples of how to use the library. All binaries come in two
flavours - Async and Lwt.

* `$ cohttp-curl-{lwt,async}`

This is a simple curl utility implemented using cohttp. An example of an
invocation is:

```
$ cohttp-curl-lwt -v -X GET "https://www.reddit.com/"
```

* `$ cohttp-server-{lwt,async}`

This binary acts in a similar fashion to the Python `SimpleHTTPServer`. Just
run `cohttp-server-async` in a directory and it will open up a local port and
serve the files over HTTP.

```
$ cohttp-server-async
```

Assuming that the server is running in cohttp's source directory:

```
$ cohttp-curl-lwt 'http://0.0.0.0:8080/README.md'
```

Other examples using the async api are avaliable in the
[examples/async](https://github.com/mirage/ocaml-cohttp/tree/master/examples)
folder in the sources

## Debugging

You can activate some runtime debugging for the servers by setting `COHTTP_DEBUG` to any value different from `0` or `false`, and it will set a default debug-level logger on stdout.

Since both Cohttp and Conduit use `Logs` for debugging output, you can enable custom debugging in your code (if needed). For example, if you intend to make use of the `COHTTP_DEBUG` env variable, you could simply use

```ocaml
let () =
  if not @@ Debug.debug_active () then (
    Fmt_tty.setup_std_outputs ();
    Logs.set_level ~all:true level;
    Logs.set_reporter Debug.default_reporter);
```

Of course you are free to completely override it and use your own reporters, for example by adding something like the following to your code (courtesy of @dinosaure).

```ocaml
let reporter ppf =
  let report src level ~over k msgf =
    let k _ =
      over () ;
      k () in
    let with_metadata header _tags k ppf fmt =
      Format.kfprintf k ppf
        ("%a[%a]: " ^^ fmt ^^ "\n%!")
        Logs_fmt.pp_header (level, header)
        Fmt.(styled `Magenta string)
        (Logs.Src.name src) in
    msgf @@ fun ?header ?tags fmt -> with_metadata header tags k ppf fmt in
  { Logs.report }

let () =
  Fmt_tty.setup_std_outputs ~style_renderer:`Ansi_tty ~utf_8:true ();
  Logs.set_reporter (reporter Fmt.stderr);
  Logs.set_level ~all:true (Some Logs.Debug)
```

Note that you can selectively filter out the logs produced by `cohttp-lwt` and `cohttp-lwt-unix` internals as follows.

```ocaml
let () =
  (* Set log level v for all loggers, this does also affect cohttp internal loggers *)
  Logs.set_level ~all:true level;
  (* Disable all cohttp-lwt and cohttp-lwt-unix logs *)
  List.iter (fun src ->
      match Logs.Src.name src with
      | "cohttp.lwt.io" | "cohttp.lwt.server" -> Logs.Src.set_level src None
      | _ -> ())
  @@ Logs.Src.list ()
```

## Important Links

- [Cohttp API Documentation](https://mirage.github.io/ocaml-cohttp/)
- [Conduit API Documentation](https://mirage.github.io/ocaml-conduit/)
