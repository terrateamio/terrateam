type err = [ `Error of string ]

module Response = struct
  type 'a t = {
    headers : (string * string) list;
    status : int;
    value : 'a;
  }
  [@@deriving show]

  let make ~headers ~status value = { headers; status; value }
  let value t = t.value
  let headers t = t.headers
  let status t = t.status
end

module Request = struct
  module Var = struct
    type _ v =
      | Array : 'a v -> 'a list v
      | Option : 'a v -> 'a option v
      | Int : int v
      | String : string v
      | Bool : bool v

    type t = Var : ('a * 'a v) -> t

    let rec to_uritmpl_var : type a. a v -> a -> Uritmpl.Var.v option =
     fun t v ->
      match (t, v) with
      | Int, v -> Some (Uritmpl.Var.S (CCInt.to_string v))
      | String, v -> Some (Uritmpl.Var.S v)
      | Bool, v -> Some (Uritmpl.Var.S (Bool.to_string v))
      | Option t, Some v -> to_uritmpl_var t v
      | Option _, None -> None
      | Array t, arr ->
          Some
            (Uritmpl.Var.A
               (CCList.map (function
                    | Uritmpl.Var.S s -> s
                    | Uritmpl.Var.A _ -> assert false
                    | Uritmpl.Var.M _ -> assert false)
               @@ CCList.filter_map (to_uritmpl_var t) arr))
  end

  type 'a t = {
    meth : [ `Get | `Post | `Patch | `Delete | `Put ];
    url : Uri.t;
    headers : (string * string) list;
    body : string option;
    responses : (string * (string -> ('a, string) result)) list;
  }

  let make ?body ~headers ~url_params ~query_params ~url ~responses meth =
    let body = CCOption.map Yojson.Safe.to_string body in
    let to_uritmpl_var =
      CCList.filter_map (fun (n, Var.Var (v, t)) ->
          CCOption.map (fun v -> (n, v)) (Var.to_uritmpl_var t v))
    in
    let headers =
      headers
      |> to_uritmpl_var
      |> CCList.map (fun (n, v) ->
             match v with
             | Uritmpl.Var.S s -> (n, s)
             | _ -> assert false)
    in
    let url_params = to_uritmpl_var url_params in
    let query_params =
      query_params
      |> to_uritmpl_var
      |> CCList.map (fun (n, v) ->
             match v with
             | Uritmpl.Var.S s -> (n, [ s ])
             | Uritmpl.Var.A arr -> (n, arr)
             | Uritmpl.Var.M _ -> assert false)
    in
    let url =
      url
      |> Uritmpl.of_string
      |> CCResult.get_exn
      |> CCFun.flip Uritmpl.expand url_params
      |> Uri.of_string
      |> CCFun.flip Uri.with_query query_params
    in
    { meth; url; headers; body; responses }

  let with_base_url url t = { t with url = Uri.(of_string (to_string url ^ to_string t.url)) }
  let with_url url t = { t with url }
  let add_headers headers t = { t with headers = headers @ t.headers }
end

module type IO = sig
  type 'a t
  type err

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val return : 'a -> 'a t

  val call :
    ?body:string ->
    headers:(string * string) list ->
    meth:[ `Get | `Post | `Delete | `Patch | `Put ] ->
    Uri.t ->
    (string Response.t, [> `Io_err of err ]) result t
end

module Make (Io : IO) = struct
  let ( >>= ) = Io.( >>= )

  let call { Request.meth; url; headers; body; responses } =
    Io.call ?body ~headers ~meth url
    >>= function
    | Ok resp -> (
        let status = CCInt.to_string (Response.status resp) in
        match CCList.assoc_opt ~eq:CCString.equal status responses with
        | Some conv -> (
            match conv (Response.value resp) with
            | Ok v -> Io.return (Ok Response.{ resp with value = v })
            | Error str -> Io.return (Error (`Conversion_err (str, resp))))
        | None -> Io.return (Error (`Missing_response resp)))
    | Error _ as err -> Io.return err
end

let of_json_body to_t of_yojson body =
  try
    let json = Yojson.Safe.from_string body in
    CCResult.map to_t (of_yojson json)
  with Yojson.Json_error err -> Error err
