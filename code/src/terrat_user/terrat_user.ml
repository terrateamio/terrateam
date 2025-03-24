type t = {
  avatar_url : string option;
  email : string option;
  id : Uuidm.t;
  name : string option;
}
[@@deriving show, eq]

module Sql = struct
  let select_user_installation () =
    Pgsql_io.Typed_sql.(
      sql
      // (* installation_id *) Ret.bigint
      /^ "select installation_id from github_user_installations where user_id = $user_id and \
          installation_id = $installation_id"
      /% Var.uuid "user_id"
      /% Var.bigint "installation_id")
end

let make ?email ?name ?avatar_url ~id () = { avatar_url; email; id; name }
let avatar_url t = t.avatar_url
let email t = t.email
let id t = t.id
let name t = t.name

let enforce_installation_access storage user installation_id ctx =
  let open Abb.Future.Infix_monad in
  Pgsql_pool.with_conn storage ~f:(fun db ->
      Pgsql_io.Prepared_stmt.fetch
        db
        (Sql.select_user_installation ())
        ~f:CCFun.id
        (id user)
        (CCInt64.of_int installation_id))
  >>= function
  | Ok (_ :: _) -> Abb.Future.return (Ok ())
  | Ok [] -> Abb.Future.return (Error (Brtl_ctx.set_response `Forbidden ctx))
  | Error (#Pgsql_pool.err as err) ->
      Logs.err (fun m ->
          m
            "ENFORCE_INSTALLATION_ACCESS : %s : ERROR : %a"
            (Brtl_ctx.token ctx)
            Pgsql_pool.pp_err
            err);
      Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
  | Error (#Pgsql_io.err as err) ->
      Logs.err (fun m ->
          m "ENFORCE_INSTALLATION_ACCESS : %s : ERROR : %a" (Brtl_ctx.token ctx) Pgsql_io.pp_err err);
      Abb.Future.return (Error (Brtl_ctx.set_response `Internal_server_error ctx))
