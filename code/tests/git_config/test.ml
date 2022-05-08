let test1 =
  Oth.test ~name:"Basic 1" (fun _ ->
      let config = "# Core variables\n[core]\n\t; Don't trust file modes\nfilemode = false" in
      match Git_config.of_string config with
      | Ok c -> assert (Git_config.(value (Key.section "core") "filemode" c = Some [ "false" ]))
      | Error (#Git_config.err as err) -> raise (Failure (Git_config.show_err err)))

let test2 =
  Oth.test ~name:"Basic 2" (fun _ ->
      let config = "[branch \"devel\"]\n\tremote = origin\n\tmerge = refs/heads/devel" in
      match Git_config.of_string config with
      | Ok c ->
          assert (
            Git_config.(value (Key.subsection "branch" "devel") "remote" c = Some [ "origin" ]));
          assert (
            Git_config.(
              value (Key.subsection "branch" "devel") "merge" c = Some [ "refs/heads/devel" ]))
      | Error (#Git_config.err as err) -> raise (Failure (Git_config.show_err err)))

let test3 =
  Oth.test ~name:"Basic 3" (fun _ ->
      let config =
        "# Proxy settings\n\
         [core]\n\
         \tgitProxy=\"ssh\" for \"kernel.org\"\n\
         \tgitProxy=default-proxy ; for the rest"
      in
      match Git_config.of_string config with
      | Ok c ->
          assert (
            Git_config.(
              value (Key.section "core") "gitproxy" c
              = Some [ "\"ssh\" for \"kernel.org\""; "default-proxy" ]))
      | Error (#Git_config.err as err) -> raise (Failure (Git_config.show_err err)))

let test4 =
  Oth.test ~name:"Basic 4" (fun _ ->
      let config =
        "[include]\n\
         \tpath = /path/to/foo.inc ; include by absolute path\n\
         \tpath = foo ; expand \"foo\" relative to the current file\n\
         \tpath = ~/foo ; expand \"foo\" in your $HOME directory"
      in
      match Git_config.of_string config with
      | Ok c ->
          assert (
            Git_config.(
              value (Key.section "include") "path" c = Some [ "/path/to/foo.inc"; "foo"; "~/foo" ]))
      | Error (#Git_config.err as err) -> raise (Failure (Git_config.show_err err)))

let test5 =
  Oth.test ~name:"Basic 5" (fun _ ->
      let config =
        "; HTTP\n\
         [http]\n\
         \tsslVerify\n\
         [http \"https://weak.example.com\"]\n\
         \tsslVerify = false\n\
         \tcookieFile = /tmp/cookie.txt"
      in
      match Git_config.of_string config with
      | Ok c ->
          assert (Git_config.(value (Key.section "http") "sslVerify" c = Some [ "true" ]));
          assert (
            Git_config.(
              value (Key.subsection "http" "https://weak.example.com") "sslVerify" c
              = Some [ "false" ]));
          assert (
            Git_config.(
              value (Key.subsection "http" "https://weak.example.com") "cookieFile" c
              = Some [ "/tmp/cookie.txt" ]))
      | Error (#Git_config.err as err) -> raise (Failure (Git_config.show_err err)))

let test = Oth.parallel [ test1; test2; test3; test4; test5 ]

let () =
  Random.self_init ();
  Oth.run test
