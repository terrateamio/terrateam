module At = Brtl_js2.Brr.At

let open_in_new () =
  Brtl_js2.Brr.El.(
    span
      ~at:At.[ class' (Jstr.v "material-icons") ]
      [ span ~at:At.[ class' (Jstr.v "text-lg") ] [ txt' "open_in_new" ] ])

let render_state state =
  let open Brtl_js2.Brr.El in
  div
    ~at:At.[ class' (Jstr.v "state") ]
    [
      div
        ~at:At.[ class' (Jstr.v state) ]
        [
          img
            ~at:
              At.
                [
                  src
                    (Jstr.v
                       (match state with
                       | "open" -> "/assets/pull-request-open.svg"
                       | "closed" | "merged" -> "/assets/pull-request-closed.svg"
                       | _ -> "/assets/pull-request.svg"));
                  class' (Jstr.v "w-10");
                  class' (Jstr.v "h-10");
                ]
            ();
        ];
      div
        ~at:At.[ class' (Jstr.v "text") ]
        [
          txt'
            (match state with
            | "open" -> "Open"
            | "closed" -> "Closed"
            | "merged" -> "Merged"
            | _ -> assert false);
        ];
    ]

let render_details_btn pr_send pr =
  let module Pr = Terrat_api_components.Installation_pull_request in
  let open Brtl_js2.Brr.El in
  div
    ~at:At.[ class' (Jstr.v "details-link") ]
    [
      Brtl_js2.Kit.Ui.Button.el
        (Brtl_js2.Kit.Ui.Button.v'
           ~action:(fun () ->
             pr_send pr;
             Abb_js.Future.return ())
           (Brtl_js2.Note.S.const ~eq:( == ) Brtl_js2.Brr.El.[ txt' "Details" ])
           ());
    ]

let run
    (pr_send : Terrat_api_components.Installation_pull_request.t Brtl_js2.Note.E.send option)
    pr
    state =
  let module Pr = Terrat_api_components.Installation_pull_request in
  let open Brtl_js2.Brr.El in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       ([
          render_state pr.Pr.state;
          div
            ~at:At.[ class' (Jstr.v "details") ]
            [
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Title" ];
                  div [ txt' (CCOption.get_or ~default:"" pr.Pr.title) ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Repository" ];
                  div
                    [
                      span [ txt' (pr.Pr.owner ^ "/" ^ pr.Pr.name) ];
                      a
                        ~at:
                          At.
                            [
                              v (Jstr.v "target") (Jstr.v "_blank");
                              href
                                (Jstr.v
                                   (Printf.sprintf
                                      "https://github.com/%s/%s"
                                      pr.Pr.owner
                                      pr.Pr.name));
                            ]
                        [ open_in_new () ];
                    ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Pull Request #" ];
                  div
                    [
                      span [ txt' (CCInt.to_string pr.Pr.pull_number) ];
                      a
                        ~at:
                          At.
                            [
                              v (Jstr.v "target") (Jstr.v "_blank");
                              href
                                (Jstr.v
                                   (Printf.sprintf
                                      "https://github.com/%s/%s/pull/%d"
                                      pr.Pr.owner
                                      pr.Pr.name
                                      pr.Pr.pull_number));
                            ]
                        [ open_in_new () ];
                    ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "User" ];
                  div [ txt' (CCOption.get_or ~default:"" pr.Pr.user) ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Destination Branch" ];
                  div [ txt' pr.Pr.base_branch ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Destination Commit" ];
                  div
                    [
                      span [ txt' pr.Pr.base_sha ];
                      a
                        ~at:
                          At.
                            [
                              v (Jstr.v "target") (Jstr.v "_blank");
                              href
                                (Jstr.v
                                   (Printf.sprintf
                                      "https://github.com/%s/%s/commit/%s"
                                      pr.Pr.owner
                                      pr.Pr.name
                                      pr.Pr.base_sha));
                            ]
                        [ open_in_new () ];
                    ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Branch" ]; div [ txt' pr.Pr.branch ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Commit" ];
                  div
                    [
                      span [ txt' pr.Pr.sha ];
                      a
                        ~at:
                          At.
                            [
                              v (Jstr.v "target") (Jstr.v "_blank");
                              href
                                (Jstr.v
                                   (Printf.sprintf
                                      "https://github.com/%s/%s/commit/%s"
                                      pr.Pr.owner
                                      pr.Pr.name
                                      pr.Pr.sha));
                            ]
                        [ open_in_new () ];
                    ];
                ];
              div
                ~at:At.[ class' (Jstr.v "h-pair") ]
                [
                  div ~at:At.[ class' (Jstr.v "name") ] [ txt' "Last Run" ];
                  div
                    [
                      txt'
                        (CCOption.map_or
                           ~default:"--"
                           CCFun.(Brtl_js2_datetime.(of_string %> to_yyyy_mm_dd_hh_mm))
                           pr.Pr.latest_work_manifest_run_at);
                    ];
                ];
            ];
        ]
       @
       match pr_send with
       | Some pr_send -> [ render_details_btn pr_send pr ]
       | None -> []))
