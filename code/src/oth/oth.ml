module List = ListLabels

module Assert = struct
  exception Failure of string

  let ok ~pp r =
    match r with
    | Ok v -> v
    | Error e -> raise (Failure (Format.asprintf "Expected Ok (_), got Error:\n%a" pp e))

  let some ~fail_msg opt =
    match opt with
    | Some v -> v
    | None -> raise (Failure fail_msg)

  let eq ~eq ~pp expected actual =
    if not (eq expected actual) then
      raise (Failure (Format.asprintf "Expected:\n%a\nGot:\n%a" pp expected pp actual))
end

(*
 * This isn't here actually but will be used to propogate
 * options at some point
 *)
module State = struct
  type t = unit

  let create () = ()
end

module Test_result = struct
  type t = {
    name : string;
    desc : string option;
    duration : Duration.t;
    res : [ `Ok | `Exn of exn * Printexc.raw_backtrace option | `Timedout ];
  }
end

module Run_result = struct
  type t = Test_result.t list

  let of_test_results = CCFun.id
  let test_results = CCFun.id
end

module Test = struct
  type t = State.t -> Run_result.t
end

module Outputter = struct
  type t = Run_result.t -> unit

  let string_of_exn exn =
    match exn with
    | Assert.Failure msg -> msg
    | _ -> Printexc.to_string exn

  let basic_stdout =
    List.iter ~f:(fun tr ->
        match tr.Test_result.res with
        | `Timedout -> Printf.printf "Test: %s\t\tTIMEDOUT\n" tr.Test_result.name
        | `Ok ->
            Printf.printf
              "Test: %s\t\tPASSED (%0.02f sec)\n"
              tr.Test_result.name
              (Duration.to_f tr.Test_result.duration)
        | `Exn (exn, bt_opt) ->
            Printf.printf
              "Test: %s\t\tFAILED (%0.02f sec)\n"
              tr.Test_result.name
              (Duration.to_f tr.Test_result.duration);
            CCOption.iter (Printf.printf "Description: %s\n") tr.Test_result.desc;
            Printf.printf "Exn: %s\n" (string_of_exn exn);
            CCOption.iter
              (Printf.printf "Backtrace: %s\n")
              (CCOption.map Printexc.raw_backtrace_to_string bt_opt))

  let basic_tap out rr =
    let oc, close =
      match out with
      | `Filename s -> (open_out s, close_out)
      | `Out_channel oc -> (oc, CCFun.const ())
    in
    let num_tests = List.length rr in
    let start_test = 1 in
    let end_test = num_tests in
    Printf.fprintf oc "%d..%d\n" start_test end_test;
    let rec output_test n = function
      | [] -> ()
      | tr :: trs ->
          assert (n <= end_test);
          (match tr.Test_result.res with
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
                   (CCOption.get_or ~default:"" tr.Test_result.desc));
              Printf.fprintf
                oc
                "# Exn: %s\n"
                (CCString.replace ~which:`All ~sub:"\n" ~by:"\n# " (string_of_exn exn));
              Printf.fprintf
                oc
                "# Backtrace: %s\n"
                (CCString.replace
                   ~which:`All
                   ~sub:"\n"
                   ~by:"\n# "
                   (CCOption.get_or
                      ~default:""
                      (CCOption.map Printexc.raw_backtrace_to_string bt_opt))));
          output_test (n + 1) trs
    in
    output_test start_test rr;
    close oc

  let of_env ?(default = []) env_name outputter_map rr =
    let outputters =
      let outputter_names =
        try CCString.Split.list_cpy ~by:" " (Sys.getenv env_name) with Not_found -> default
      in
      List.map
        ~f:(fun on -> CCList.Assoc.get_exn ~eq:CCString.equal on outputter_map)
        outputter_names
    in
    List.iter ~f:(fun outputter -> outputter rr) outputters
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

let serial tests state = List.concat (List.map ~f:(fun test -> test state) tests)
let parallel = serial

let test ?desc ~name f state =
  let duration, res = time_test state f in
  Test_result.[ { name; desc; duration; res } ]

let raw_test f state = f state

let result_test rtest state =
  let res = rtest state in
  match res with
  | Ok _ -> ()
  | Error _ -> assert false

let test_with_revops ?desc ~name ~revops tst =
  test ?desc ~name (fun state -> Revops.run_in_context revops (CCFun.flip tst state))

let eval test = test (State.create ())

let main outputter test =
  let rr = eval test in
  outputter rr;
  List.iter
    ~f:(fun tr ->
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
    with Not_found -> Filename.basename Sys.executable_name
  in
  let tap_output_name = tap_output_base_name ^ ".tap" in
  let outputter =
    Outputter.of_env
      ~default:[ "stdout"; "tap" ]
      "OTH_OUTPUTTER"
      [
        ("stdout", Outputter.basic_stdout); ("tap", Outputter.basic_tap (`Filename tap_output_name));
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

module Diff = struct
  let diff_files ~expected_file_path ~actual_file_path =
    let command = Printf.sprintf "diff -u %s %s" expected_file_path actual_file_path in
    match Sys.command command with
    | 0 -> ()
    | _ ->
        print_endline
          (Format.sprintf
             "Output does not match expected. Run the following command to see the diff:\n\
              diff -u %s %s"
             expected_file_path
             actual_file_path);
        assert false

  let check ~tmp_dir_name ~expected_file_path ~actual_content =
    if String.equal (CCOption.get_or ~default:"0" (Sys.getenv_opt "OTH_CREATE_EXPECTED_FILES")) "1"
    then CCIO.with_out expected_file_path (fun oc -> output_string oc actual_content)
    else
      let tmp_dir = Filename.temp_dir (tmp_dir_name ^ "-") "-XXX" in
      let actual_file_path = Filename.concat tmp_dir "actual.txt" in
      CCIO.with_out actual_file_path (fun oc -> output_string oc actual_content);
      diff_files ~expected_file_path ~actual_file_path
end
