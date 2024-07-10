module At = Brtl_js2.Brr.At

let workflow_file =
  "##########################################################################\n\
   # DO NOT MODIFY\n\
   #\n\
   # THIS FILE SHOULD LIVE IN .github/workflows/terrateam.yml\n\
   #\n\
   # Looking for the Terrateam configuration file? .terrateam/config.yml.\n\
   #\n\
   # See https://terrateam.io/docs\n\
   ##########################################################################\n\
  \ name: 'Terrateam Workflow'\n\
  \ on:\n\
  \   workflow_dispatch:\n\
  \     inputs:\n\
  \       # The work-token and api-base-url are automatically passed in by the Terrateam backend\n\
  \       work-token:\n\
  \         description: 'Work Token'\n\
  \         required: true\n\
  \       api-base-url:\n\
  \         description: 'API Base URL'\n\
  \       environment:\n\
  \         description: 'Environment in which to run the action'\n\
  \         type: environment\n\
  \ jobs:\n\
  \   terrateam:\n\
  \     permissions: # Required to pass credentials to the Terrateam action\n\
  \       id-token: write\n\
  \       contents: read\n\
  \     runs-on: ubuntu-latest\n\
  \     timeout-minutes: 1440\n\
  \     name: Terrateam Action\n\
  \     environment: '${{ github.event.inputs.environment }}'\n\
  \     steps:\n\
  \       - uses: actions/checkout@v3\n\
  \       - name: Run Terrateam Action\n\
  \         id: terrateam\n\
  \         uses: terrateamio/action@v1\n\
  \         with:\n\
  \           work-token: '${{ github.event.inputs.work-token }}'\n\
  \           api-base-url: '${{ github.event.inputs.api-base-url }}'\n\
  \         env:\n\
  \           SECRETS_CONTEXT: ${{ toJson(secrets) }}\n\
  \           VARIABLES_CONTEXT: ${{ toJson(vars) }}"

let workflow_file_syntax_highlight =
  "<span class=\"hl \
   slc\">##########################################################################</span>\n\
   <span class=\"hl slc\"># DO NOT MODIFY</span>\n\
   <span class=\"hl slc\">#</span>\n\
   <span class=\"hl slc\"># THIS FILE SHOULD LIVE IN .github/workflows/terrateam.yml</span>\n\
   <span class=\"hl slc\">#</span>\n\
   <span class=\"hl slc\"># Looking for the Terrateam configuration file? \
   .terrateam/config.yml.</span>\n\
   <span class=\"hl slc\">#</span>\n\
   <span class=\"hl slc\"># See https://terrateam.io/docs</span>\n\
   <span class=\"hl \
   slc\">##########################################################################</span>\n\
  \ <span class=\"hl kwa\">name:</span> <span class=\"hl sng\">&#39;Terrateam Workflow&#39;</span>\n\
  \ <span class=\"hl kwa\">on:</span>\n\
  \   <span class=\"hl kwa\">workflow_dispatch:</span>\n\
  \     <span class=\"hl kwa\">inputs:</span>\n\
  \       <span class=\"hl slc\"># The work-token and api-base-url are automatically passed in by \
   the Terrateam backend</span>\n\
  \       <span class=\"hl kwa\">work-token:</span>\n\
  \         <span class=\"hl kwa\">description:</span> <span class=\"hl sng\">&#39;Work \
   Token&#39;</span>\n\
  \         <span class=\"hl kwa\">required:</span> true\n\
  \       <span class=\"hl kwa\">api-base-url:</span>\n\
  \         <span class=\"hl kwa\">description:</span> <span class=\"hl sng\">&#39;API Base \
   URL&#39;</span>\n\
  \       <span class=\"hl kwa\">environment:</span>\n\
  \         <span class=\"hl kwa\">description:</span> <span class=\"hl sng\">&#39;Environment in \
   which to run the action&#39;</span>\n\
  \         <span class=\"hl kwa\">type:</span> environment\n\
  \ <span class=\"hl kwa\">jobs:</span>\n\
  \   <span class=\"hl kwa\">terrateam:</span>\n\
  \     <span class=\"hl kwa\">permissions:</span> <span class=\"hl slc\"># Required to pass \
   credentials to the Terrateam action</span>\n\
  \       <span class=\"hl kwa\">id-token:</span> write\n\
  \       <span class=\"hl kwa\">contents:</span> read\n\
  \     <span class=\"hl kwa\">runs-on:</span> ubuntu<span class=\"hl opt\">-</span>latest\n\
  \     <span class=\"hl kwa\">timeout-minutes:</span> <span class=\"hl num\">1440</span>\n\
  \     <span class=\"hl kwa\">name:</span> Terrateam Action\n\
  \     <span class=\"hl kwa\">environment:</span> <span class=\"hl sng\">&#39;${{ \
   github.event.inputs.environment }}&#39;</span>\n\
  \     <span class=\"hl kwa\">steps:</span>\n\
  \       <span class=\"hl opt\">-</span> <span class=\"hl kwa\">uses:</span> \
   actions/checkout&#64;v3\n\
  \       <span class=\"hl opt\">-</span> <span class=\"hl kwa\">name:</span> Run Terrateam Action\n\
  \         <span class=\"hl kwa\">id:</span> terrateam\n\
  \         <span class=\"hl kwa\">uses:</span> terrateamio/action&#64;v1\n\
  \         <span class=\"hl kwa\">with:</span>\n\
  \           <span class=\"hl kwa\">work-token:</span> <span class=\"hl sng\">&#39;${{ \
   github.event.inputs.work-token }}&#39;</span>\n\
  \           <span class=\"hl kwa\">api-base-url:</span> <span class=\"hl sng\">&#39;${{ \
   github.event.inputs.api-base-url }}&#39;</span>\n\
  \         <span class=\"hl kwa\">env:</span>\n\
  \           <span class=\"hl kwa\">SECRETS_CONTEXT:</span> $<span class=\"hl opt\">{{</span> \
   toJson<span class=\"hl opt\">(</span>secrets<span class=\"hl opt\">) }}</span>\n\
  \           <span class=\"hl kwa\">VARIABLES_CONTEXT:</span> $<span class=\"hl opt\">{{</span> \
   toJson<span class=\"hl opt\">(</span>vars<span class=\"hl opt\">) }}</span>"

let run repo_name state =
  let app_state = Brtl_js2.State.app_state state in
  let workflow = Brtl_js2.Brr.El.pre ~at:At.[ class' (Jstr.v "hl") ] [] in
  let workflow_jv = Brtl_js2.Brr.El.to_jv workflow in
  Jv.set workflow_jv "innerHTML" (Jv.of_jstr (Jstr.v workflow_file_syntax_highlight));
  let btn =
    Brtl_js2.Kit.Ui.Button.v'
      ~class':(Jstr.v "setup-repo-copy")
      ~action:(fun () ->
        let open Abb_js.Future.Infix_monad in
        let t = Brtl_js2.Io.Clipboard.of_navigator Brtl_js2.Brr.G.navigator in
        Brtl_js2.Io.Clipboard.write_text t (Jstr.v workflow_file)
        >>= fun _ ->
        Terrat_ui_js_state.notify
          app_state
          (Terrat_ui_js_notification.msg_success Brtl_js2.Brr.El.[ txt' "Copied" ]);
        Abb_js.Future.return ())
      (Brtl_js2.Note.S.const
         ~eq:( == )
         Brtl_js2.Brr.El.
           [ txt' "Copy"; span ~at:At.[ class' (Jstr.v "material-icons") ] [ txt' "content_copy" ] ])
      ()
  in
  Abb_js.Future.return
    (Brtl_js2.Output.const
       Brtl_js2.Brr.El.
         [
           div ~at:At.[ class' (Jstr.v "setup-repo-title") ] [ txt' "Setup repo" ];
           div
             ~at:At.[ class' (Jstr.v "setup-repo-step") ]
             [
               h1 [ txt' "Step 1" ];
               div
                 [
                   span [ txt' " Copy the GitHub Action Workflow file into " ];
                   code [ txt' ".github/workflows/terrateam.yml" ];
                   span [ txt' " make sure it is in the default branch, usually " ];
                   code [ txt' "main" ];
                   span [ txt' " or " ];
                   code [ txt' "master" ];
                   span [ txt' "." ];
                 ];
             ];
           div
             ~at:At.[ class' (Jstr.v "workflow-file") ]
             [
               div ~at:At.[ class' (Jstr.v "workflow-file-content") ] [ workflow ];
               div ~at:At.[ class' (Jstr.v "workflow-file-copy") ] [ Brtl_js2.Kit.Ui.Button.el btn ];
             ];
           div
             ~at:At.[ class' (Jstr.v "setup-repo-step") ]
             [
               h1 [ txt' "Step 2" ];
               span
                 [
                   txt'
                     " Setup your cloud providers.  Terrateam needs permission to access your \
                      cloud provider in order to make changes with the Terraform CLI. ";
                 ];
               ul
                 ~at:At.[ class' (Jstr.v "cloud-provider-list") ]
                 [
                   li
                     [
                       a
                         ~at:
                           At.
                             [
                               href (Jstr.v "https://terrateam.io/docs/cloud-provider-setup/aws");
                               v (Jstr.v "target") (Jstr.v "_blank");
                             ]
                         [ txt' "AWS" ];
                     ];
                   li
                     [
                       a
                         ~at:
                           At.
                             [
                               href (Jstr.v "https://terrateam.io/docs/cloud-provider-setup/gcp");
                               v (Jstr.v "target") (Jstr.v "_blank");
                             ]
                         [ txt' "GCP" ];
                     ];
                   li
                     [
                       a
                         ~at:
                           At.
                             [
                               href (Jstr.v "https://terrateam.io/docs/cloud-provider-setup/azure");
                               v (Jstr.v "target") (Jstr.v "_blank");
                             ]
                         [ txt' "Azure" ];
                     ];
                   li
                     [
                       a
                         ~at:
                           At.
                             [
                               href (Jstr.v "https://terrateam.io/docs/cloud-provider-setup/other");
                               v (Jstr.v "target") (Jstr.v "_blank");
                             ]
                         [ txt' "Other" ];
                     ];
                 ];
             ];
           div
             ~at:At.[ class' (Jstr.v "setup-repo-step") ]
             [
               h1 [ txt' "Step 3" ];
               div
                 [
                   txt'
                     "Starting making pull requests!  Once you've merged the GitHub Actions \
                      workflow file and set up your cloud provider, new pull requests with \
                      Terraform or OpenTofu changes will trigger a Terrateam operation.";
                 ];
               div
                 [
                   txt' "Learn how to fully customize Terrateam with our runtime ";
                   a
                     ~at:
                       At.
                         [
                           href (Jstr.v "https://terrateam.io/docs/configuration");
                           v (Jstr.v "target") (Jstr.v "_blank");
                         ]
                     [ txt' "configuration file" ];
                   txt' ".";
                 ];
               div
                 ~at:At.[ class' (Jstr.v "setup-repo-help") ]
                 [
                   h1 [ txt' "Need help?  " ];
                   div
                     [
                       txt' "We provide collaborative onboarding support, just join our ";
                       a
                         ~at:
                           At.
                             [
                               href (Jstr.v "https://terrateam.io/slack");
                               v (Jstr.v "target") (Jstr.v "_blank");
                             ]
                         [ txt' "Slack" ];
                       txt' ".";
                     ];
                 ];
             ];
         ])
