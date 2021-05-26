module Std_random = Random

let pat_chars =
  CCString.to_list "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890[]%.()-=*?$^"

let str ?(len = QCheck.Gen.int_bound 10) =
  let open QCheck.Gen in
  list_size len (oneofl pat_chars) >>= fun l -> return (CCString.of_list l)

(* This validates that random patterns do not case the matcher to crash *)
let pattern_does_not_crash_prop =
  QCheck.Test.make
    ~count:10000
    ~max_gen:10000
    ~name:"Pattern check"
    (QCheck.make
       ~print:QCheck.Print.(pair string string)
       QCheck.Gen.(pair (str ~len:(int_bound 100)) str))
    (fun (str, pat) ->
      match Lua_pattern.of_string pat with
        | None   -> true
        | Some p -> (
            match CCResult.guard (fun () -> Lua_pattern.mtch str p) with
              | Ok _    -> true
              | Error _ -> false))

let prop_tests =
  Oth.test ~name:"Prop Tests" (fun _ ->
      QCheck.Test.check_exn ~rand:(Std_random.State.make_self_init ()) pattern_does_not_crash_prop)

let () = Oth.run prop_tests
