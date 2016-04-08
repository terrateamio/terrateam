(* Implementation of basic revops for system operations. *)

open Core.Std

let temp_file ?(prefix="Temp") ?(suffix = "CleanMe") () =
  Revops.Oprev.make
    (fun () -> Filename.temp_file prefix suffix)
    (fun filename -> Unix.remove filename)
