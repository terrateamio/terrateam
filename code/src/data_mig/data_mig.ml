module type S = sig
  type t

  type err

  val get_schema_version : t -> (string option, err) result Abb.Future.t

  val set_schema_version : t -> name:string -> version:string -> (unit, err) result Abb.Future.t
end

module Migrate (M : S) = struct
  module Migration = struct
    type t = M.t -> (unit, M.err) result Abb.Future.t
  end

  let get_schema_version mt =
    let open Abbs_future_combinators.Infix_result_monad in
    M.get_schema_version mt
    >>| fun version_opt -> CCOpt.get_or ~default:0 (CCOpt.flat_map CCInt.of_string version_opt)

  let rec exec mt v = function
    | []              -> Abb.Future.return (Ok ())
    | (name, m) :: ms ->
        let open Abbs_future_combinators.Infix_result_monad in
        Logs.info (fun m -> m "Performing migration %s" name);
        m mt
        >>= fun () ->
        let v = v + 1 in
        M.set_schema_version mt ~name ~version:(CCInt.to_string v) >>= fun () -> exec mt v ms

  let run mt ms =
    let open Abbs_future_combinators.Infix_result_monad in
    get_schema_version mt
    >>= fun version ->
    let migrations = CCList.drop version ms in
    exec mt version migrations
end
