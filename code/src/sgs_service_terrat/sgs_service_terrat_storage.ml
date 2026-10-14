type t = Terrat_storage.t
type opt = Sgs_svc_mngr.t
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

let ty = Ty

let matches (type a) (q : a Sgs_service.ty) : (t, a) Sgs_service.eq option =
  match q with
  | Ty -> Some Sgs_service.Refl
  | _ -> None

let name = "terrat_storage"

let show_err = function
  | #Pgsql_io.err as err -> Pgsql_io.show_err err
  | #Pgsql_pool.err as err -> Pgsql_pool.show_err err

let start mgr =
  let open Abbs_fc.Infix_result_monad in
  Sgs_svc_mngr.load ~name:Sgs_service_terrat_config.name Sgs_service_terrat_config.Ty mgr
  >>= fun config ->
  Abbs_fc.Result.map_err
    ~f:(fun err -> `Start_err (show_err err))
    (Terrat_storage.try_create config)

let routes _ = []
let stop _ = Abb.Future.return ()
