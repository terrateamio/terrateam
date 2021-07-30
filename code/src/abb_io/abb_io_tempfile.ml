let num_tries = 1000

module Make (Abb : Abb_intf.S) = struct
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  let with_filename ?temp_dir ~prefix ~suffix f =
    try
      let fname = Filename.temp_file ?temp_dir prefix suffix in
      Fut_comb.with_finally
        (fun () -> f fname)
        ~finally:(fun () -> Fut_comb.ignore (Abb.File.unlink fname))
    with Sys_error str -> Abb.Future.return (Error (`Temp_file_error str))

  let rec rm_rf dir_name =
    let open Abb.Future.Infix_monad in
    Abb.File.readdir dir_name
    >>= function
    | Ok files       -> (
        Fut_comb.List_result.iter
          ~f:(fun fname ->
            Abb.File.unlink (Filename.concat dir_name fname)
            >>= function
            | Ok () -> Abb.Future.return (Ok ())
            | Error `E_is_dir -> rm_rf (Filename.concat dir_name fname)
            | ( Error `E_not_dir
              | Error `E_loop
              | Error `E_no_space
              | Error `E_permission
              | Error (`Unexpected _)
              | Error `E_io
              | Error `E_name_too_long
              | Error `E_no_entity
              | Error `E_access ) as err -> Abb.Future.return err)
          files
        >>= function
        | Ok ()          -> Abb.File.rmdir dir_name
        | Error _ as err -> Abb.Future.return err)
    | Error _ as err -> Abb.Future.return err

  let temp_file_name temp_dir prefix suffix =
    let rnd = Random.int 999999 in
    Filename.concat temp_dir (Printf.sprintf "%s%06x%s" prefix rnd suffix)

  let with_dirname ?temp_dir ~prefix ~suffix f =
    let temp_dir = CCOpt.get_or ~default:(Filename.get_temp_dir_name ()) temp_dir in
    let rec try_create = function
      | 0 -> Abb.Future.return (Error `Temp_dir_error)
      | n -> (
          let open Abb.Future.Infix_monad in
          let dir_name = temp_file_name temp_dir prefix suffix in
          Abb.File.mkdir dir_name 0o700
          >>= function
          | Ok () ->
              Fut_comb.with_finally
                (fun () -> f dir_name)
                ~finally:(fun () -> Fut_comb.ignore (rm_rf dir_name))
          | Error `E_exists | Error `E_is_dir -> try_create (n - 1)
          | Error `E_not_dir
          | Error `E_loop
          | Error `E_no_space
          | Error `E_permission
          | Error (`Unexpected _)
          | Error `E_io
          | Error `E_name_too_long
          | Error `E_no_entity
          | Error `E_access -> Abb.Future.return (Error `Temp_dir_error))
    in
    try_create num_tries
end
