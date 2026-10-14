type t =
  [ `License
  | `Register
  | `Done
  ]
[@@deriving show, eq]

let next ~requirement config db =
  let open Abbs_fc.Infix_result_monad in
  Sgs_service_license.passes_license_gate ~requirement config db
  >>= function
  | false -> Abbs_fc.return_ok `License
  | true -> (
      match Sgs_config.oauth2 config with
      | Some _ -> Abbs_fc.return_ok `Done
      | None -> (
          Sgs_user.has_human_users db
          >>| function
          | true -> `Done
          | false -> `Register))
