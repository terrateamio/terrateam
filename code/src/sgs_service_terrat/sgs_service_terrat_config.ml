type t = Terrat_config.t
type opt = Sgs_svc_mngr.t
type 'a Sgs_service.ty += Ty : t Sgs_service.ty

let ty = Ty

let matches (type a) (q : a Sgs_service.ty) : (t, a) Sgs_service.eq option =
  match q with
  | Ty -> Some Sgs_service.Refl
  | _ -> None

let name = "terrat_config"

let start _ =
  match Sgs_terrat_config.create () with
  | Ok config -> Abbs_fc.return_ok config
  | Error (#Terrat_config.err as err) ->
      Abbs_fc.return_err (`Start_err (Terrat_config.show_err err))

let routes _ = []
let stop _ = Abb.Future.return ()
