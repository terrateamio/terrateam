module At = Brtl_js2.Brr.At

let run state =
  Abb_js.Future.return
    (Brtl_js2.Output.const
       Brtl_js2.Brr.El.
         [
           div
             ~at:At.[ class' (Jstr.v "getting-started") ]
             [
               div [ txt' "Ready to get started with Terrateam?" ];
               div
                 [
                   span
                     [
                       txt'
                         "Configure a repository by following the directions starting at Step 2 in \
                          the";
                     ];
                   a
                     ~at:
                       At.
                         [
                           href (Jstr.v "https://terrateam.io/docs/getting-started/");
                           v (Jstr.v "target") (Jstr.v "_blank");
                         ]
                     [ txt' "Getting Started Instructions" ];
                 ];
             ];
         ])
