(* When a comment is too large, step output has to be trimmed. Terraform and its providers emit the
   error at the END of a step's output, so trimming must keep the tail -- keeping the head throws
   away the only part anyone needs (#1540). *)

module P = Terrat_vcs_github_comment_publishers

let marker = "[... earlier output trimmed to fit the comment ...]"

let test =
  Oth.parallel
    [
      Oth.test ~name:"short output is returned untouched" (fun _ ->
          let s = "line one\nline two\n" in
          Oth.Assert.Eq.string ~expected:s ~actual:(P.tail_of ~max_bytes:1000 s));
      Oth.test ~name:"output exactly at the budget is untouched" (fun _ ->
          let s = CCString.repeat "a" 100 in
          Oth.Assert.Eq.string ~expected:s ~actual:(P.tail_of ~max_bytes:100 s));
      Oth.test ~name:"the tail is kept, not the head" (fun _ ->
          (* The error is last, which is the whole point. *)
          let s = CCString.repeat "noise\n" 500 ^ "Error: 403 Forbidden: read-only dashboard\n" in
          let out = P.tail_of ~max_bytes:200 s in
          Oth.Assert.str_contains ~haystack:out ~needle:"Error: 403 Forbidden";
          Oth.Assert.true_ "trimmed output is bounded" (CCString.length out < 400));
      Oth.test ~name:"a trim is announced" (fun _ ->
          let s = CCString.repeat "x\n" 500 in
          Oth.Assert.str_contains ~haystack:(P.tail_of ~max_bytes:50 s) ~needle:marker);
      Oth.test ~name:"kept text resumes at a line boundary" (fun _ ->
          let s = CCString.repeat "abcdefghij\n" 100 in
          let out = P.tail_of ~max_bytes:35 s in
          (* Everything after the marker line must be whole lines. *)
          let body =
            match CCString.Split.left ~by:"\n" out with
            | Some (_marker_line, rest) -> rest
            | None -> out
          in
          CCString.split ~by:"\n" body
          |> CCList.filter (fun l -> l <> "")
          |> CCList.iter (fun l -> Oth.Assert.Eq.string ~expected:"abcdefghij" ~actual:l));
      Oth.test ~name:"output with no newline at all still trims" (fun _ ->
          let s = CCString.repeat "z" 1000 in
          let out = P.tail_of ~max_bytes:100 s in
          Oth.Assert.str_contains ~haystack:out ~needle:marker;
          Oth.Assert.true_ "bounded" (CCString.length out < 300));
    ]

let () = Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
