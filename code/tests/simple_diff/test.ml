module Diff = Simple_diff.Make (String)

let rec pp = function
  | []                    -> ()
  | Diff.Equal vs :: ds   ->
      Printf.printf "Equal [ ";
      Array.iter (Printf.printf "%s; ") vs;
      Printf.printf "]\n";
      pp ds
  | Diff.Added vs :: ds   ->
      Printf.printf "Added [ ";
      Array.iter (Printf.printf "%s; ") vs;
      Printf.printf "]\n";
      pp ds
  | Diff.Deleted vs :: ds ->
      Printf.printf "Deleted [ ";
      Array.iter (Printf.printf "%s; ") vs;
      Printf.printf "]\n";
      pp ds

let myers_test =
  Oth.test ~desc:"Myers test" ~name:"Myers" (fun _ ->
      let old = [| "A"; "B"; "C"; "A"; "B"; "B"; "A" |] in
      let revised = [| "C"; "B"; "A"; "B"; "A"; "C" |] in
      let diff = Diff.get_diff old revised in
      assert (
        diff
        = Diff.
            [
              Deleted [| "A"; "B" |];
              Equal [| "C" |];
              Added [| "B" |];
              Equal [| "A"; "B" |];
              Deleted [| "B" |];
              Equal [| "A" |];
              Added [| "C" |];
            ] ))

let simple_equal_test =
  Oth.test ~desc:"No changes" ~name:"Simple equal" (fun _ ->
      let old = [| "1" |] in
      let revised = [| "1" |] in
      let diff = Diff.get_diff old revised in
      assert (diff = [ Diff.Equal [| "1" |] ]))

let equal_test =
  Oth.test ~desc:"No changes" ~name:"Equal" (fun _ ->
      let old = [| "1"; "2" |] in
      let revised = [| "1"; "2" |] in
      let diff = Diff.get_diff old revised in
      assert (diff = [ Diff.Equal [| "1"; "2" |] ]))

let simple_add_test =
  Oth.test ~desc:"Add one line" ~name:"Simple add" (fun _ ->
      let old = [| "1"; "2" |] in
      let revised = [| "1"; "2"; "3" |] in
      let diff = Diff.get_diff old revised in
      assert (diff = [ Diff.Equal [| "1"; "2" |]; Diff.Added [| "3" |] ]))

let simple_delete_test =
  Oth.test ~desc:"Delete one line" ~name:"Simple delete" (fun _ ->
      let old = [| "1"; "2" |] in
      let revised = [| "1" |] in
      let diff = Diff.get_diff old revised in
      assert (diff = [ Diff.Equal [| "1" |]; Diff.Deleted [| "2" |] ]))

let simple_conflict_test =
  Oth.test ~desc:"Conflict one line" ~name:"Simple conflict" (fun _ ->
      let old = [| "1"; "2"; "3" |] in
      let revised = [| "1"; "4"; "3" |] in
      let diff = Diff.get_diff old revised in
      assert (
        diff
        = [
            Diff.Equal [| "1" |]; Diff.Deleted [| "2" |]; Diff.Added [| "4" |]; Diff.Equal [| "3" |];
          ] ))

let beginning_conflict_test =
  Oth.test ~desc:"Conflict in beginning" ~name:"Beginning conflict" (fun _ ->
      let old = [| "1"; "2"; "3" |] in
      let revised = [| "4"; "2"; "3" |] in
      let diff = Diff.get_diff old revised in
      assert (diff = [ Diff.Deleted [| "1" |]; Diff.Added [| "4" |]; Diff.Equal [| "2"; "3" |] ]))

let complex_test =
  Oth.test ~desc:"Complex conflicts" ~name:"Complex conflict" (fun _ ->
      let old =
        [|
          "Aidan Gillen:";
          "  aboolean: 'true'";
          "  array:";
          "    - Game of Thrones";
          "    - The Wire";
          "  boolean: false";
          "  int: '2'";
          "  object:";
          "    foo: bar";
          "  otherint: 4";
          "  string: some string";
          "Alexander Skarsg?rd:";
          "  - Generation Kill";
          "  - True Blood";
          "Alice Farmer:";
          "  - The Corner";
          "  - Oz";
          "  - The Wire";
          "Amy Ryan:";
          "  - In Treatment";
          "  - The Wire";
          "Annie Fitzgerald:";
          "  - True Blood";
          "  - Big Love";
          "  - The Sopranos";
          "  - Oz";
          "Anwan Glover:";
          "  - Treme";
          "  - The Wire";
        |]
      in
      let revised =
        [|
          "Aidan Gillen:";
          "  aboolean: true";
          "  array:";
          "    - Game of Thron\"es";
          "    - The Wire";
          "  boolean: true";
          "  int: 2";
          "  object:";
          "    foo: bar";
          "    object1:";
          "      new prop1: new prop value";
          "    object2:";
          "      new prop1: new prop value";
          "    object3:";
          "      new prop1: new prop value";
          "    object4:";
          "      new prop1: new prop value";
          "  string: some string";
          "Alexander Skarsgard:";
          "  - Generation Kill";
          "  - True Blood";
          "Amy Ryan:";
          "  one: In Treatment";
          "  two: The Wire";
          "Annie Fitzgerald:";
          "  - Big Love";
          "  - True Blood";
          "Anwan Glover:";
          "  - Treme";
          "  - The Wire";
          "Clarke Peters: null";
        |]
      in
      let diff = Diff.get_diff old revised in
      assert (
        diff
        = Diff.
            [
              Equal [| "Aidan Gillen:" |];
              Deleted [| "  aboolean: 'true'" |];
              Added [| "  aboolean: true" |];
              Equal [| "  array:" |];
              Deleted [| "    - Game of Thrones" |];
              Added [| "    - Game of Thron\"es" |];
              Equal [| "    - The Wire" |];
              Deleted [| "  boolean: false"; "  int: '2'" |];
              Added [| "  boolean: true"; "  int: 2" |];
              Equal [| "  object:"; "    foo: bar" |];
              Deleted [| "  otherint: 4" |];
              Added
                [|
                  "    object1:";
                  "      new prop1: new prop value";
                  "    object2:";
                  "      new prop1: new prop value";
                  "    object3:";
                  "      new prop1: new prop value";
                  "    object4:";
                  "      new prop1: new prop value";
                |];
              Equal [| "  string: some string" |];
              Deleted [| "Alexander Skarsg?rd:" |];
              Added [| "Alexander Skarsgard:" |];
              Equal [| "  - Generation Kill"; "  - True Blood" |];
              Deleted [| "Alice Farmer:"; "  - The Corner"; "  - Oz"; "  - The Wire" |];
              Equal [| "Amy Ryan:" |];
              Deleted [| "  - In Treatment"; "  - The Wire" |];
              Added [| "  one: In Treatment"; "  two: The Wire" |];
              Equal [| "Annie Fitzgerald:" |];
              Deleted [| "  - True Blood" |];
              Equal [| "  - Big Love" |];
              Deleted [| "  - The Sopranos"; "  - Oz" |];
              Added [| "  - True Blood" |];
              Equal [| "Anwan Glover:"; "  - Treme"; "  - The Wire" |];
              Added [| "Clarke Peters: null" |];
            ] ))

let test =
  Oth.parallel
    [
      myers_test;
      simple_equal_test;
      equal_test;
      simple_add_test;
      simple_delete_test;
      simple_conflict_test;
      beginning_conflict_test;
      complex_test;
    ]

let () =
  Random.self_init ();
  Oth.run test
