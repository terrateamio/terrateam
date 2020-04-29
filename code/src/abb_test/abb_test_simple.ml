module Make =
functor
  (Abb : Abb_intf.S)
  ->
  struct
    module Oth_abb = Oth_abb.Make (Abb)

    let close_write_cb () =
      let open Abb.Future.Infix_monad in
      Abb.File.open_file ~flags:Abb_intf.File.Flag.[ Read_only ] "/tmp/foo.txt"
      >>= function
      | Ok file -> (
          let buf = Bytes.create 1024 in
          Abb.File.read file ~buf ~pos:0 ~len:(Bytes.length buf)
          >>= function
          | Ok n    ->
              Printf.printf "read %d bytes\n%s\n" n (Bytes.sub_string buf 0 n);
              Abb.File.close file >>= fun _ -> Abb.Future.return ()
          | Error _ -> assert false )
      | Error _ -> assert false

    let file_io_test =
      Oth_abb.test ~desc:"Simple file I/O test" ~name:"File I/O" (fun () ->
          let open Abb.Future.Infix_monad in
          Abb.File.open_file ~flags:Abb_intf.File.Flag.[ Write_only; Create 0o666 ] "/tmp/foo.txt"
          >>= function
          | Ok file               -> (
              let buf = Bytes.of_string "testing" in
              Abb.File.write file Abb_intf.Write_buf.[ { buf; pos = 0; len = Bytes.length buf } ]
              >>= function
              | Ok _    -> Abb.File.close file >>= fun _ -> close_write_cb ()
              | Error _ -> assert false )
          | Error (`Unexpected e) -> raise e
          | Error _               -> assert false)

    let test = Oth_abb.serial [ file_io_test ]
  end
