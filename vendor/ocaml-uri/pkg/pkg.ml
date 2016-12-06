#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let gen_service c =
  OS.Cmd.run Cmd.(v "sh" % "etc/gen.sh")

let () =
  let build = Pkg.build ~pre:gen_service () in
  Pkg.describe "uri" ~build @@ fun c ->
  Ok [ Pkg.mllib "lib/uri.mllib";
       Pkg.mllib "lib/services.mllib";
       Pkg.mllib "lib/services_full.mllib";
       Pkg.mllib "top/uri_top.mllib";
       Pkg.test "lib_test/test_runner" ]
