module List = ListLabels

(*
 * This isn't here actually but will be used to propogate
 * options at some point
 *)
module State = struct
  type t = unit

  let create () = ()
end

module Test_result = struct
  type t = { name : string
           ; desc : string option
           ; duration : Duration.t
           ; res : [ `Ok | `Exn of (exn * Printexc.raw_backtrace option) | `Timedout ]
           }
end

module Run_result = struct
  type t = Test_result.t list
  let of_test_results = CCFun.id
  let test_results = CCFun.id
end

module Test = struct
  type t = (State.t -> Run_result.t)
end

module Outputter = struct
  type t = (Run_result.t -> unit)

  let basic_stdout =
    List.iter
      ~f:(fun tr ->
          match tr.Test_result.res with
            | `Timedout ->
              Printf.printf "Test: %s\t\tTIMEDOUT\n" tr.Test_result.name
            | `Ok ->
              Printf.printf "Test: %s\t\tPASSED (%0.02f sec)\n"
                tr.Test_result.name
                (Duration.to_f tr.Test_result.duration)
            | `Exn (exn, bt_opt) ->
              Printf.printf "Test: %s\t\tFAILED (%0.02f sec)\n"
                tr.Test_result.name
                (Duration.to_f tr.Test_result.duration);
              CCOpt.iter (Printf.printf "Description: %s\n") tr.Test_result.desc;
              Printf.printf "Exn: %s\n" (Printexc.to_string exn);
              CCOpt.iter
                (Printf.printf "Backtrace: %s\n")
                (CCOpt.map Printexc.raw_backtrace_to_string bt_opt))

  let basic_tap out rr =
    let (oc, close) =
      match out with
        | `Filename s -> (open_out s, close_out)
        | `Out_channel oc -> (oc, CCFun.const ())
    in
    let num_tests = List.length rr in
    let start_test = 1 in
    let end_test = num_tests in
    Printf.fprintf oc "%d..%d\n" start_test end_test;
    let rec output_test n = function
      | [] ->
        ()
      | tr::trs ->
        assert (n <= end_test);
        begin match tr.Test_result.res with
          | `Ok ->
            Printf.fprintf
              oc
              "ok %d %s\n# Elapsed %0.02f sec\n"
              n
              tr.Test_result.name
              (Duration.to_f tr.Test_result.duration)
          | `Timedout ->
            Printf.fprintf
              oc
              "not ok %d %s\n# Elapsed %0.02f sec\n"
              n
              tr.Test_result.name
              (Duration.to_f tr.Test_result.duration);
            Printf.fprintf oc "# TIMEDOUT\n"
          | `Exn (exn, bt_opt) ->
            Printf.fprintf
              oc
              "not ok %d %s\n# Elapsed %0.02f sec\n"
              n
              tr.Test_result.name
              (Duration.to_f tr.Test_result.duration);
            Printf.fprintf
              oc
              "# Description: %s\n"
              (CCString.replace
                 ~which:`All
                 ~sub:"\n"
                 ~by:"\n# "
                 (CCOpt.get_or ~default:"" tr.Test_result.desc));
            Printf.fprintf
              oc
              "# Exn: %s\n"
              (CCString.replace ~which:`All ~sub:"\n" ~by:"\n# " (Printexc.to_string exn));
            Printf.fprintf
              oc
              "# Backtrace: %s\n"
              (CCString.replace
                 ~which:`All
                 ~sub:"\n"
                 ~by:"\n# "
                 (CCOpt.get_or ~default:"" (CCOpt.map Printexc.raw_backtrace_to_string bt_opt)))
        end;
        output_test (n + 1) trs
    in
    output_test start_test rr;
    close oc

  let of_env ?(default = []) env_name outputter_map rr =
    let outputters =
      let outputter_names =
        try
          CCString.Split.list_cpy ~by:" " (Sys.getenv env_name)
        with
          | Not_found ->
            default
      in
      List.map
        ~f:(fun on -> CCList.Assoc.get_exn on outputter_map)
        outputter_names
    in
    List.iter
      ~f:(fun outputter -> outputter rr)
      outputters
end

let time_test s f =
  let start = Unix.gettimeofday () in
  let res =
    match CCResult.guard (fun () -> f s) with
      | Ok () -> `Ok
      | Error exn -> `Exn (exn, Some (Printexc.get_raw_backtrace ()))
  in
  let stop = Unix.gettimeofday () in
  let duration = Duration.of_f (stop -. start) in
  (duration, res)

let serial tests state =
  List.concat
    (List.map
       ~f:(fun test -> test state)
       tests)

let parallel = serial

let test ?desc ~name f state =
  let (duration, res) = time_test state f in
  Test_result.([{ name; desc; duration; res }])

let raw_test f state = f state

let result_test rtest state =
  let res = rtest state in
  match res with
    | Ok _ -> ()
    | Error _ -> assert false

let test_with_revops ?desc ~name ~revops tst =
  test
    ?desc
    ~name
    (fun state -> Revops.run_in_context revops (CCFun.flip tst state))

let eval test =
  test (State.create ())

let main outputter test =
  let rr = eval test in
  outputter rr;
  List.iter
    (fun tr ->
       match tr.Test_result.res with
         | `Ok -> ()
         | _ -> exit 1)
    rr;
  exit 0

let run test =
  let tap_output_base_name =
    try
      let dir = Sys.getenv "OTH_TAP_DIR" in
      Filename.concat dir (Filename.basename Sys.executable_name)
    with
      | Not_found ->
        Filename.basename Sys.executable_name
  in
  let tap_output_name = tap_output_base_name ^ ".tap" in
  let outputter =
    Outputter.of_env
      ~default:["stdout"; "tap"]
      "OTH_OUTPUTTER"
      [ ("stdout", Outputter.basic_stdout)
      ; ("tap", Outputter.basic_tap (`Filename tap_output_name))
      ]
  in
  main outputter test

let timeout span t = failwith "timeout not implemented"

let name ~name test = test

let loop n test state =
  let rec loop' = function
    | 0 -> []
    | n -> test state @ loop' (n - 1)
  in
  loop' n

let verbose = CCFun.id
let silent = CCFun.id
