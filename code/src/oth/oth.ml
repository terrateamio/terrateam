module List = ListLabels

module Assert = struct
  exception Failure of string

  let ok ?fail_msg r =
    match r with
    | Ok v -> v
    | Error _ -> raise (Failure (CCOption.get_or ~default:"Expected Ok, got Error" fail_msg))

  let ok_pp ~pp r =
    match r with
    | Ok v -> v
    | Error e -> raise (Failure (Format.asprintf "Expected Ok (_), got Error:\n%a" pp e))

  let error ?fail_msg r =
    match r with
    | Ok _ -> raise (Failure (CCOption.get_or ~default:"Expected Error, got Ok" fail_msg))
    | Error e -> e

  let error_pp ~pp r =
    match r with
    | Ok v -> raise (Failure (Format.asprintf "Expected Error (_), got Ok:\n%a" pp v))
    | Error e -> e

  let some ?fail_msg opt =
    match opt with
    | Some v -> v
    | None -> raise (Failure (CCOption.get_or ~default:"Expected Some, got None" fail_msg))

  let none ?fail_msg opt =
    match opt with
    | None -> ()
    | Some _ -> raise (Failure (CCOption.get_or ~default:"Expected None, got Some" fail_msg))

  let none_pp ~pp opt =
    match opt with
    | None -> ()
    | Some v -> raise (Failure (Format.asprintf "Expected None, got Some:@.@[%a@]" pp v))

  let eq ~eq ~pp expected actual =
    if not (eq expected actual) then
      raise (Failure (Format.asprintf "Expected:@.@[%a@]@.Got:@.@[%a@]" pp expected pp actual))

  let true_ msg v = if not v then raise (Failure msg)
  let false_ msg = raise (Failure msg)

  let str_contains ~haystack ~needle =
    if not (CCString.find ~sub:needle haystack >= 0) then
      raise
        (Failure
           (Format.asprintf
              "Expected HAYSTACK to contain NEEDLE, but it doesn't! See \
               below.@.HAYSTACK:@.%s@.NEEDLE:@.%s"
              haystack
              needle))

  let str_contains_all ~haystack ~needles =
    CCList.iter (fun needle -> str_contains ~haystack ~needle) needles

  let str_doesnt_contain ~haystack ~needle =
    if CCString.find ~sub:needle haystack >= 0 then
      raise
        (Failure
           (Format.asprintf
              "Expected HAYSTACK to not contain NEEDLE, but it does! See \
               below.@.HAYSTACK:@.%s@.NEEDLE:@.%s"
              haystack
              needle))

  module List = struct
    let length ~expected l =
      let actual = CCList.length l in
      if actual <> expected then
        raise (Failure (Format.asprintf "Expected list of length %d, got %d" expected actual))

    let length_one = function
      | [ x ] -> x
      | l -> raise (Failure (Format.asprintf "Expected list of length 1, got %d" (CCList.length l)))

    let non_empty = function
      | [] -> raise (Failure "Expected list to be non-empty, got empty list")
      | x :: _ -> x

    let empty l =
      if not (CCList.is_empty l) then
        false_
          (Format.asprintf "Expected list to be empty, got list of length %d" (CCList.length l))
  end

  module Eq = struct
    let string ~expected ~actual = eq ~eq:String.equal ~pp:Format.pp_print_string expected actual
    let int ~expected ~actual = eq ~eq:Int.equal ~pp:Format.pp_print_int expected actual
    let bool ~expected ~actual = eq ~eq:Bool.equal ~pp:Format.pp_print_bool expected actual

    let option ~eq:eq_inner ~pp:pp_inner ~expected ~actual =
      let eq_opt = CCOption.equal eq_inner in
      let pp_opt fmt = function
        | Some v -> Format.fprintf fmt "Some(%a)" pp_inner v
        | None -> Format.fprintf fmt "None"
      in
      eq ~eq:eq_opt ~pp:pp_opt expected actual

    let string_option ~expected ~actual =
      option ~eq:String.equal ~pp:Format.pp_print_string ~expected ~actual

    let list ~eq:eq_item ~pp:pp_item ~expected ~actual =
      if not (CCList.equal eq_item expected actual) then (
        let buf = Buffer.create 256 in
        let fmt = Format.formatter_of_buffer buf in
        let n_exp = CCList.length expected in
        let n_act = CCList.length actual in
        let n_common = min n_exp n_act in
        (* Compare common items *)
        for i = 0 to n_common - 1 do
          let e = CCList.nth expected i in
          let a = CCList.nth actual i in
          if not (eq_item e a) then
            Format.fprintf
              fmt
              "Item %d differs:@.  expected: %a@.  got:      %a@."
              i
              pp_item
              e
              pp_item
              a
        done;
        (* Report length difference with the extra/missing items *)
        if n_exp <> n_act then (
          let label, n_diff, items =
            if n_act > n_exp then ("extra", n_act - n_exp, actual)
            else ("missing", n_exp - n_act, expected)
          in
          Format.fprintf fmt "%d %s item(s) (expected %d, got %d):@." n_diff label n_exp n_act;
          for i = n_common to CCList.length items - 1 do
            Format.fprintf fmt "  [%d]: %a@." i pp_item (CCList.nth items i)
          done);
        Format.pp_print_flush fmt ();
        raise (Failure (Buffer.contents buf)))

    let string_list = list ~eq:CCString.equal ~pp:Format.pp_print_string
    let int_list = list ~eq:Int.equal ~pp:Format.pp_print_int
    let bool_list = list ~eq:Bool.equal ~pp:Format.pp_print_bool
  end

  module String = struct
    let empty s =
      if not (CCString.is_empty s) then
        false_ (Format.asprintf "Expected string to be empty, but got: %s" s)

    let doesnt_contain_any ~haystack ~needles =
      CCList.iter (fun needle -> str_doesnt_contain ~haystack ~needle) needles
  end

  module Exit_code = struct
    let zero = function
      | Abb_intf.Process.Exit_code.Exited 0 -> ()
      | Abb_intf.Process.Exit_code.Exited rc ->
          raise (Failure (Format.sprintf "Expected a zero return code, but got %d" rc))
      | Abb_intf.Process.Exit_code.Signaled _ -> raise (Failure "Expected 'Exited', got 'Signaled'")
      | Abb_intf.Process.Exit_code.Stopped _ -> raise (Failure "Expected 'Exited', got 'Stopped'")

    let non_zero = function
      | Abb_intf.Process.Exit_code.Exited 0 ->
          raise (Failure "Expected a non-zero return code, but got zero")
      | Abb_intf.Process.Exit_code.Exited _ -> ()
      | Abb_intf.Process.Exit_code.Signaled _ -> raise (Failure "Expected 'Exited', got 'Signaled'")
      | Abb_intf.Process.Exit_code.Stopped _ -> raise (Failure "Expected 'Exited', got 'Stopped'")
  end
end

module Tag = struct
  module Set = CCSet.Make (CCString)

  let default = "default"

  (** [file] is [Stdlib.__FILE__] *)
  let file_dir_tags file =
    let parts = CCString.split_on_char '/' file in
    let rec drop_prefix = function
      | [] -> []
      | ("src" | "tests") :: rest ->
          (* We only keep directory segments that are within [code/{src,test}] *)
          rest
      | _ :: rest -> drop_prefix rest
    in
    drop_prefix parts

  let of_env_opt env_name =
    match Sys.getenv_opt env_name with
    | Some s when CCString.length (CCString.trim s) > 0 ->
        let tags_list =
          s
          |> CCString.trim
          |> CCString.Split.list_cpy ~by:" "
          (* Handle case where OTH_TAGS has multiple spaces in a row *)
          |> CCList.filter (fun s -> not (CCString.is_empty s))
        in
        Some (Set.of_list tags_list)
    | Some _ | None -> None

  (** Determine whether a test with the given tags should run, given the include and exclude sets.
      [~tags] should include explicit tags, file-dir tags, and the default tag. A test runs when it
      matches at least one include tag (or include is [None]) and matches no exclude tags. *)
  let should_run ~include_tags ~exclude_tags ~tags =
    let tag_set = Set.of_list tags in
    let included =
      match include_tags with
      | None -> true
      | Some inc -> not (Set.is_empty (Set.inter tag_set inc))
    in
    let excluded =
      match exclude_tags with
      | None -> false
      | Some exc -> not (Set.is_empty (Set.inter tag_set exc))
    in
    included && not excluded
end

module State = struct
  type t = {
    file_dir_tags : string list;
    print_tags : bool;
    pool : Domainslib.Task.pool;
  }

  let create ~print_tags ~file ~pool () =
    let file_dir_tags = Tag.file_dir_tags file in
    { file_dir_tags; print_tags; pool }

  let file_dir_tags t = t.file_dir_tags
  let print_tags t = t.print_tags
  let pool t = t.pool
end

let all_tags ~name ~tags state = (Tag.default :: name :: tags) @ State.file_dir_tags state

let test_should_run ~tags =
  let include_tags = Tag.of_env_opt "OTH_TAGS" in
  let exclude_tags = Tag.of_env_opt "OTH_EXCLUDE_TAGS" in
  Tag.should_run ~include_tags ~exclude_tags ~tags

let print_test_tags ~tags =
  Printf.printf "%s\n" (CCString.concat " " (CCList.sort CCString.compare tags))

module Test_result = struct
  type t = {
    name : string;
    desc : string option;
    duration : Duration.t;
    res : [ `Ok | `Exn of exn * Printexc.raw_backtrace option | `Timedout | `Skipped ];
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
        (* Skipped tests are intentionally silent on stdout: with many tag
           filters in play the per-test SKIPPED lines drown out the actual
           result.  The summary line printed by [main] still reports the
           total skipped count, and [basic_tap] continues to emit `ok N ...
           # SKIP tag filtered` so the TAP aggregator's view is unchanged. *)
        | `Skipped -> ()
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
          | `Skipped -> Printf.fprintf oc "ok %d %s # SKIP tag filtered\n" n tr.Test_result.name
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

let parallel tests state =
  let pool = State.pool state in
  let promises = CCList.map (fun test -> Domainslib.Task.async pool (fun () -> test state)) tests in
  CCList.flat_map (Domainslib.Task.await pool) promises

let test ?(tags = []) ?desc ~name f state =
  let tags = all_tags ~name ~tags state in
  if State.print_tags state then (
    print_test_tags ~tags;
    [])
  else if not (test_should_run ~tags) then
    Test_result.[ { name; desc; duration = Duration.of_f 0.0; res = `Skipped } ]
  else
    let duration, res = time_test state f in
    Test_result.[ { name; desc; duration; res } ]

let raw_test f state = f state

let result_test rtest state =
  let res = rtest state in
  match res with
  | Ok _ -> ()
  | Error _ -> assert false

let test_with_revops ?tags ?desc ~name ~revops tst =
  test ?tags ?desc ~name (fun state -> Revops.run_in_context revops (CCFun.flip tst state))

let parallelism () =
  match Sys.getenv_opt "OTH_PARALLEL" with
  | Some s -> ( try max 1 (int_of_string (CCString.trim s)) with Failure _ -> 1)
  | None -> 1

let with_pool f =
  let n = parallelism () in
  let pool = Domainslib.Task.setup_pool ~num_domains:(n - 1) () in
  Fun.protect ~finally:(fun () -> Domainslib.Task.teardown_pool pool) (fun () -> f pool)

let eval ~file test =
  with_pool (fun pool ->
      Domainslib.Task.run pool (fun () -> test (State.create ~print_tags:false ~file ~pool ())))

let print_tags ~file test =
  with_pool (fun pool ->
      let state = State.create ~print_tags:true ~file ~pool () in
      ignore (test state));
  exit 0

let main ~file ?(finally = fun () -> ()) outputter test =
  if CCOption.is_some (Sys.getenv_opt "OTH_PRINT_TAGS") then print_tags ~file test;
  let rr = eval ~file test in
  outputter rr;
  let non_skipped =
    CCList.filter
      (fun tr ->
        match tr.Test_result.res with
        | `Skipped -> false
        | _ -> true)
      rr
  in
  let total_tests = CCList.length non_skipped in
  let passed_tests =
    CCList.filter
      (fun tr ->
        match tr.Test_result.res with
        | `Ok -> true
        | _ -> false)
      non_skipped
    |> CCList.length
  in
  let skipped_tests = CCList.length rr - CCList.length non_skipped in
  let success_percentage =
    if total_tests > 0 then float_of_int passed_tests /. float_of_int total_tests *. 100.0 else 0.0
  in
  let skipped_suffix =
    if skipped_tests > 0 then Printf.sprintf ", %d skipped" skipped_tests else ""
  in
  Printf.printf
    "Tests passed: %d/%d (%.2f%%)%s\n"
    passed_tests
    total_tests
    success_percentage
    skipped_suffix;
  let has_failure =
    CCList.exists
      (fun tr ->
        match tr.Test_result.res with
        | `Ok | `Skipped -> false
        | _ -> true)
      rr
  in
  finally ();
  if has_failure then exit 1 else exit 0

let run ~file ?finally test =
  let tap_output_base_name =
    (* exec_name is either test.byte or test.native *)
    let exec_name = Filename.basename Sys.executable_name in
    match Sys.getenv_opt "OTH_TAP_DIR" with
    | Some dir ->
        (* By virtue of our build, this dirname is either a child directory of code/src
           or code/tests *)
        let dirname_enclosing_execution = Filename.basename (Sys.getcwd ()) in
        Filename.concat dir (dirname_enclosing_execution ^ "-" ^ exec_name)
    | None -> exec_name
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
  main ~file ?finally outputter test

let timeout _span _t = failwith "timeout not implemented"
let name ~name:_ test = test

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
             {|Output does not match expected. Run the following command to see the diff:
diff -u %s %s
To regenerate the expected files, run the test with OTH_CREATE_EXPECTED_FILES=1.|}
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
