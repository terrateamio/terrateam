module Std_random = Random

open Core.Std

let pat_chars =
  String.to_list
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890[]%.()-=*?$^"

let str ?(len = QCheck.Arbitrary.int 10) =
  let open QCheck.Arbitrary in
  list ~len (among pat_chars)
  >>= fun l ->
  return (String.of_char_list l)

(* This validates that random patterns do not case the matcher to crash *)
let pattern_does_not_crash_prop =
  QCheck.mk_test
    ~n:10000
    ~name:"Pattern check"
    ~pp:QCheck.PP.(pair string string)
    QCheck.Arbitrary.(pair (str ~len:(int 100)) str)
    (fun (str, pat) ->
      match Lua_pattern.of_string pat with
        | None ->
          true
        | Some p -> begin
          let r = Result.try_with (fun () -> Lua_pattern.mtch str p) in
          Result.is_ok r
        end)

let prop_tests _ =
  assert (QCheck.run_tests
            ~rand:(Std_random.State.make_self_init ())
            [pattern_does_not_crash_prop])

let () =
  Oth.(
    run
      (test ~name:"Prop Tests" prop_tests))
