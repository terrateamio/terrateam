(* Decode tests for the GitLab webhook payloads Terrateam receives.

   Two things make these worth having.  First, [Gitlab_webhooks.Event.of_yojson]
   is a [one_of] that tries each event type in order and takes the first that
   parses, and every record is [strict = false], so a payload can quietly decode
   as the wrong event if the field sets overlap.  Asserting the constructor, not
   just that decoding succeeded, is the point.

   Second, the merge request [action] enum is the surface that produced audit
   item 03: the event handler matched five of its nine values and raised on the
   rest.  Covering all nine here means a value added to the enum without a
   handler shows up in a fast test rather than as a 500 in production. *)

module E = Gitlab_webhooks.Event

let project =
  {|{"default_branch":"main","id":42,"name":"tf","namespace":"acme",
     "path_with_namespace":"acme/tf"}|}

(* A project in nested subgroups.  The event handler splits this on the first
   slash, so it is worth having a payload of this shape decode. *)
let nested_project =
  {|{"default_branch":"main","id":43,"name":"tf","namespace":"deep",
     "path_with_namespace":"acme/team/deep/tf"}|}

let repository = {|{"name":"tf"}|}
let user = {|{"id":7,"username":"someone"}|}

let decode name body expected =
  Oth.test ~name (fun _ ->
      match Gitlab_webhooks_decoder.run body with
      | Ok event when expected event -> ()
      | Ok event ->
          Printf.eprintf "decoded as the wrong event: %s\n%!" (E.show event);
          assert false
      | Error err ->
          Printf.eprintf "%s\n%!" (Gitlab_webhooks_decoder.show_err err);
          assert false)

let is_push = function
  | E.Push_event _ -> true
  | _ -> false

let is_merge_request = function
  | E.Merge_request_event _ -> true
  | _ -> false

let is_comment = function
  | E.Merge_request_comment_event _ -> true
  | _ -> false

let is_pipeline = function
  | E.Pipeline_event _ -> true
  | _ -> false

let is_job = function
  | E.Job_event _ -> true
  | _ -> false

let push_event project =
  Printf.sprintf
    {|{"checkout_sha":"abc123","event_name":"push","object_kind":"push",
       "project":%s,"project_id":42,"ref":"refs/heads/main",
       "repository":%s,"user_username":"someone"}|}
    project
    repository

let merge_request_event action =
  Printf.sprintf
    {|{"event_type":"merge_request","object_kind":"merge_request",
       "object_attributes":{"action":"%s","id":1,"iid":2},
       "project":%s,"repository":%s,"user":%s}|}
    action
    project
    repository
    user

let comment_event =
  Printf.sprintf
    {|{"event_type":"note","object_kind":"note",
       "object_attributes":{"action":"create","id":9,"note":"terrateam plan",
                            "created_at":"2026-07-21T00:00:00Z"},
       "merge_request":{"created_at":"2026-07-21T00:00:00Z","id":1,"iid":2,
                        "source":%s,"source_branch":"topic",
                        "target":%s,"target_branch":"main"},
       "project":%s,"project_id":42,"repository":%s,"user":%s}|}
    project
    project
    project
    repository
    user

let pipeline_event =
  Printf.sprintf
    {|{"object_kind":"pipeline",
       "object_attributes":{"created_at":"2026-07-21T00:00:00Z","id":1,"iid":2,
                            "ref":"topic","stages":["terrateam"],"status":"success"},
       "project":%s,"user":%s}|}
    project
    user

let job_event status =
  Printf.sprintf
    {|{"object_kind":"build","build_id":5,"build_name":"terrateam_job",
       "build_stage":"terrateam","build_status":"%s","project":%s,
       "ref":"topic","sha":"abc123","repository":%s,"user":%s}|}
    status
    project
    repository
    user

(* All nine values Gitlab_webhooks_merge_request_event.Object_attributes.Action
   decodes.  Approval, approved, unapproval and unapproved are the ones the
   event handler used to raise on. *)
let merge_request_actions =
  [
    "approval"; "approved"; "close"; "merge"; "open"; "reopen"; "unapproval"; "unapproved"; "update";
  ]

let test_push = decode "push" (push_event project) is_push

let test_push_nested_project =
  decode "push, project in nested subgroups" (push_event nested_project) is_push

let test_merge_request_actions =
  List.map
    (fun action ->
      decode ("merge request, action " ^ action) (merge_request_event action) is_merge_request)
    merge_request_actions

let test_comment = decode "merge request comment" comment_event is_comment
let test_pipeline = decode "pipeline" pipeline_event is_pipeline
let test_job_success = decode "job, success" (job_event "success") is_job
let test_job_failed = decode "job, failed" (job_event "failed") is_job

(* An unknown action must be a decode error rather than decoding as some other
   event type, which is what would happen if the enum silently accepted it. *)
let test_unknown_action =
  Oth.test ~name:"merge request, unknown action is rejected" (fun _ ->
      match Gitlab_webhooks_decoder.run (merge_request_event "wat") with
      | Error (`Parse_json_error _) -> ()
      | Ok event ->
          Printf.eprintf "unknown action decoded as %s\n%!" (E.show event);
          assert false)

let test_malformed =
  Oth.test ~name:"malformed body is an error, not an exception" (fun _ ->
      match Gitlab_webhooks_decoder.run "{not json" with
      | Error (`Parse_json_error _) -> ()
      | Ok _ -> assert false)

let test =
  Oth.parallel
    ([
       test_push;
       test_push_nested_project;
       test_comment;
       test_pipeline;
       test_job_success;
       test_job_failed;
       test_unknown_action;
       test_malformed;
     ]
    @ test_merge_request_actions)

let () =
  Random.self_init ();
  Oth.run test
