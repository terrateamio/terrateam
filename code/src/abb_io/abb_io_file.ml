module Make (Abb : Abb_intf.S) = struct
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  type with_file_err =
    [ Abb_intf.Errors.open_file
    | Abb_intf.Errors.close
    ]

  let with_file_in ~f fname =
    let open Fut_comb.Infix_result_monad in
    Abb.File.open_file ~flags:[ Abb_intf.File.Flag.Read_only ] fname
    >>= fun file ->
    Fut_comb.with_finally
      (fun () -> f file)
      ~finally:(fun () -> Fut_comb.ignore (Abb.File.close file))

  let with_file_out ?(permissions = 0o600) ~f fname =
    let open Fut_comb.Infix_result_monad in
    Abb.File.open_file ~flags:Abb_intf.File.Flag.[ Truncate; Write_only; Create permissions ] fname
    >>= fun file ->
    Fut_comb.with_finally
      (fun () -> f file)
      ~finally:(fun () -> Fut_comb.ignore (Abb.File.close file))

  let with_file_app ?(permissions = 0o600) ~f fname =
    let open Fut_comb.Infix_result_monad in
    Abb.File.open_file ~flags:Abb_intf.File.Flag.[ Append; Create permissions ] fname
    >>= fun file ->
    Fut_comb.with_finally
      (fun () -> f file)
      ~finally:(fun () -> Fut_comb.ignore (Abb.File.close file))

  let read_file ?(buf_size = 1024) fname =
    with_file_in fname ~f:(fun file ->
        let buffer = Buffer.create 1024 in
        let bytes = Bytes.create buf_size in
        let len = Bytes.length bytes in
        let rec read_data buffer file bytes =
          let open Fut_comb.Infix_result_monad in
          Abb.File.read file ~buf:bytes ~pos:0 ~len
          >>= function
          | 0 -> Abb.Future.return (Ok (Buffer.contents buffer))
          | n ->
              Buffer.add_subbytes buffer bytes 0 n;
              read_data buffer file bytes
        in
        read_data buffer file bytes)

  let write_file ~fname content =
    with_file_out fname ~f:(fun file ->
        let buf =
          Abb_intf.Write_buf.
            { buf = Bytes.unsafe_of_string content; pos = 0; len = String.length content }
        in
        let rec write_data file buf =
          let open Fut_comb.Infix_result_monad in
          Abb.File.write file [ buf ]
          >>= function
          | n when n = buf.Abb_intf.Write_buf.len -> Abb.Future.return (Ok ())
          | n ->
              write_data file Abb_intf.Write_buf.{ buf with pos = buf.pos + n; len = buf.len - n }
        in
        write_data file buf)
end
