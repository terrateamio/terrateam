(* The cap on the per-dirspace commit checks of a pull request.  A pull request which impacts more
   dirspaces than the cap gets no per-dirspace checks of a run type, which is what the
   notifications setting of that run type turned off gives the user. *)

module N = Terrat_base_repo_config_v1.Notifications
module Sc = Terrat_vcs_event_evaluator2.Status_checks

let ds dir = { Terrat_dirspace.dir; workspace = "default" }
let a = ds "a"
let b = ds "b"
let c = ds "c"

let plan_off =
  N.make ~plan:(N.Plan.make ~status_checks:(N.Status_checks.make ~enabled:false ()) ()) ()

let apply_off =
  N.make ~apply:(N.Apply.make ~status_checks:(N.Status_checks.make ~enabled:false ()) ()) ()

let enabled ~notifications ~impacted ~run =
  Sc.enabled ~notifications ~impacted_dirspaces:impacted ~run

(* The name is the failure message, so a failure names the case that is wrong. *)
let assert_decision name expected actual =
  if expected then Oth.Assert.true_ ~fail_msg:name actual
  else Oth.Assert.not_true ~fail_msg:name actual

let test_plan_cap =
  Oth.test ~name:"the plan checks stop above the cap" (fun _ ->
      assert_decision
        "a pull request which impacts exactly the cap gets its plan checks"
        true
        (enabled ~notifications:(N.make ()) ~impacted:Sc.plan_threshold ~run:`Plan);
      assert_decision
        "one dirspace more and it gets none"
        false
        (enabled ~notifications:(N.make ()) ~impacted:(Sc.plan_threshold + 1) ~run:`Plan);
      ())

let test_apply_cap =
  Oth.test ~name:"the apply checks stop above the cap" (fun _ ->
      assert_decision
        "a pull request which impacts exactly the cap gets its apply checks"
        true
        (enabled ~notifications:(N.make ()) ~impacted:Sc.apply_threshold ~run:`Apply);
      assert_decision
        "one dirspace more and it gets none"
        false
        (enabled ~notifications:(N.make ()) ~impacted:(Sc.apply_threshold + 1) ~run:`Apply);
      ())

let test_the_two_run_types_are_separate =
  Oth.test ~name:"the plan and the apply checks decide on their own" (fun _ ->
      assert_decision
        "the apply checks are off by configuration"
        false
        (enabled ~notifications:apply_off ~impacted:10 ~run:`Apply);
      assert_decision
        "the plan checks of the same pull request do not follow"
        true
        (enabled ~notifications:apply_off ~impacted:10 ~run:`Plan);
      ())

let test_cap_and_setting_agree =
  Oth.test ~name:"the cap gives the answer the setting gives" (fun _ ->
      assert_decision
        "below the cap a repository with the setting off creates nothing"
        false
        (enabled ~notifications:plan_off ~impacted:10 ~run:`Plan);
      assert_decision
        "above the cap a repository with the setting on creates nothing either"
        false
        (enabled ~notifications:(N.make ()) ~impacted:(Sc.plan_threshold + 1) ~run:`Plan);
      ())

let test_other_keeps_its_checks =
  Oth.test ~name:"a run with no setting of its own keeps its checks" (fun _ ->
      assert_decision
        "an index build above the cap still writes its check"
        true
        (enabled ~notifications:(N.make ()) ~impacted:(Sc.plan_threshold + 1) ~run:`Other);
      ())

let test_impacted_dirspaces =
  Oth.test ~name:"one dirspace which appears twice is one impacted dirspace" (fun _ ->
      Oth.Assert.Eq.int ~expected:3 ~actual:(Sc.impacted_dirspaces [ [ a; b ]; [ b; c ] ]);
      Oth.Assert.Eq.int ~expected:1 ~actual:(Sc.impacted_dirspaces [ [ a; a ] ]);
      Oth.Assert.Eq.int ~expected:0 ~actual:(Sc.impacted_dirspaces []);
      ())

let test =
  Oth.parallel
    [
      test_plan_cap;
      test_apply_cap;
      test_the_two_run_types_are_separate;
      test_cap_and_setting_agree;
      test_other_keeps_its_checks;
      test_impacted_dirspaces;
    ]

let () =
  Random.self_init ();
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
