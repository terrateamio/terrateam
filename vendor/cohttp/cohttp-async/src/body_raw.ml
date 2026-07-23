open Base
open Async_kernel
module B = Cohttp.Body

type t = [ B.t | `Pipe of string Pipe.Reader.t ] [@@deriving sexp_of]

let empty = `Empty
let of_string s = (B.of_string s :> t)
let of_pipe p = `Pipe p

let to_string = function
  | #B.t as body -> return (B.to_string body)
  | `Pipe s -> Pipe.to_list s >>| String.concat

let to_string_list = function
  | #B.t as body -> return (B.to_string_list body)
  | `Pipe s -> Pipe.to_list s

let drain = function #B.t -> return () | `Pipe p -> Pipe.drain p

let is_empty (body : t) =
  match body with
  | #B.t as body -> return (B.is_empty body)
  | `Pipe pipe -> (
      Deferred.repeat_until_finished () @@ fun () ->
      Pipe.values_available pipe >>= function
      | `Eof -> return (`Finished true)
      | `Ok -> (
          match Pipe.peek pipe with
          | None -> return (`Finished true)
          | Some "" -> (
              Pipe.read pipe >>| function
              | `Eof -> `Finished true
              | `Ok _ -> `Repeat ())
          | Some _ -> return (`Finished false)))

let to_pipe = function
  | `Empty -> Pipe.of_list []
  | `String s -> Pipe.singleton s
  | `Strings sl -> Pipe.of_list sl
  | `Pipe p -> p

let disable_chunked_encoding = function
  | #B.t as body -> return (body, B.length body)
  | `Pipe s ->
      Pipe.to_list s >>| fun l ->
      let body = `Strings l in
      let len = B.length body in
      (body, len)

let transfer_encoding = function
  | #B.t as t -> B.transfer_encoding t
  | `Pipe _ -> Cohttp.Transfer.Chunked

let of_string_list strings = `Pipe (Pipe.of_list strings)

let map t ~f =
  match t with
  | #B.t as t -> (B.map f t :> t)
  | `Pipe p -> `Pipe (Pipe.map p ~f)

let as_pipe t ~f = `Pipe (t |> to_pipe |> f)
let to_form t = to_string t >>| Uri.query_of_encoded
let of_form ?scheme f = Uri.encoded_of_query ?scheme f |> of_string

let write_body write_body (body : t) writer =
  match body with
  | `Empty -> return ()
  | `String s -> write_body writer s
  | `Strings sl -> Deferred.List.iter ~how:`Sequential sl ~f:(write_body writer)
  | `Pipe p -> Pipe.iter p ~f:(write_body writer)

let pipe_of_body read_chunk ic =
  let open Cohttp.Transfer in
  Pipe.create_reader ~close_on_exception:false (fun writer ->
      Deferred.repeat_until_finished () (fun () ->
          read_chunk ic >>= function
          | Chunk buf ->
              (* Even if [writer] has been closed, the loop must continue reading
               * from the input channel to ensure that it is left in a proper state
               * for the next request to be processed (in the case of keep-alive).
               *
               * The only case where [writer] will be closed is when
               * [Pipe.close_read] has been called on its read end. This could be
               * done by a request handler to signal that it does not need to
               * inspect the remainder of the body to fulfill the request.
               *)
              Pipe.write_when_ready writer ~f:(fun write -> write buf)
              >>| fun _ -> `Repeat ()
          | Final_chunk buf ->
              Pipe.write_when_ready writer ~f:(fun write -> write buf)
              >>| fun _ -> `Finished ()
          | Done -> return (`Finished ())))
