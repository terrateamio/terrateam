module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Tempfile = Abb_io_tempfile.Make (Abb)

let test_tempfile =
  Oth_abb.test ~desc:"Simple tempfile test" ~name:"tempfile" (fun () ->
      let open Abb.Future.Infix_monad in
      Tempfile.with_filename ~prefix:"test" ~suffix:"test" (fun _ -> Abb.Future.return (Ok ()))
      >>| fun r -> Oth.Assert.true_ "r = Ok ()" (r = Ok ()))

let test_tempfile_cleanup =
  Oth_abb.test ~desc:"Verify tempfile cleanup" ~name:"tempfile cleanup" (fun () ->
      let open Abb.Future.Infix_monad in
      let name = ref "" in
      Tempfile.with_filename ~prefix:"test" ~suffix:"test" (fun fname ->
          name := fname;
          Abb.Future.return (Ok ()))
      >>= fun r ->
      Oth.Assert.true_ "r = Ok ()" (r = Ok ());
      Oth.Assert.true_ "!name <> \"\"" (!name <> "");
      Abb.File.stat !name
      >>| fun r -> Oth.Assert.true_ "r = Error `E_no_entity" (r = Error `E_no_entity))

let test_tempdir =
  Oth_abb.test ~desc:"Simple tempdir test" ~name:"tempdir" (fun () ->
      let open Abb.Future.Infix_monad in
      Tempfile.with_dirname ~prefix:"test" ~suffix:"test" (fun dir_name ->
          Abb.File.open_file
            ~flags:Abb_intf.File.Flag.[ Write_only; Create 0o600; Truncate ]
            (Filename.concat dir_name "test")
          >>= function
          | Ok file -> Abb.File.close file >>| fun _ -> Ok ()
          | Error _ -> Oth.Assert.false_ "tempdir: unexpected value")
      >>| fun r -> Oth.Assert.true_ "r = Ok ()" (r = Ok ()))

let test_tempdir_cleanup =
  Oth_abb.test ~desc:"Verify tempdir cleanup" ~name:"tempdir cleanup" (fun () ->
      let open Abb.Future.Infix_monad in
      let name = ref "" in
      Tempfile.with_dirname ~prefix:"test" ~suffix:"test" (fun dir_name ->
          name := dir_name;
          Abb.File.open_file
            ~flags:Abb_intf.File.Flag.[ Write_only; Create 0o600; Truncate ]
            (Filename.concat dir_name "test")
          >>= function
          | Ok file -> Abb.File.close file >>| fun _ -> Ok ()
          | Error _ -> Oth.Assert.false_ "tempdir cleanup: unexpected value")
      >>= fun r ->
      Oth.Assert.true_ "r = Ok ()" (r = Ok ());
      Oth.Assert.true_ "!name <> \"\"" (!name <> "");
      Abb.File.stat !name
      >>| fun r -> Oth.Assert.true_ "r = Error `E_no_entity" (r = Error `E_no_entity))

let test =
  Oth_abb.(parallel [ test_tempfile; test_tempfile_cleanup; test_tempdir; test_tempdir_cleanup ])

let () =
  Random.self_init ();
  Oth_abb.run
    ~file:__FILE__
    ~setup:(fun () -> Abb.Future.return (Ok ()))
    ~teardown:(fun () -> Abb.Future.return ())
    (fun () -> test)
