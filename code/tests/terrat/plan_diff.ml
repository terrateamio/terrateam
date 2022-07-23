let test_simple =
  Oth.test ~name:"Test simple" (fun _ ->
      let plan_text =
        "Terraform used the selected providers to generate the following execution\n\
         plan. Resource actions are indicated with the following symbols:\n\
        \  + create\n\n\
         Terraform will perform the following actions:\n\n\
        \  # null_resource.bar will be created\n\
        \  + resource \"null_resource\" \"bar\" {\n\
        \      + id = (known after apply)\n\
        \    }\n\n\
        \  # null_resource.baz will be created\n\
        \  + resource \"null_resource\" \"baz\" {\n\
        \      + id = (known after apply)\n\
        \    }\n\n\
        \  # null_resource.foo will be created\n\
        \  ~ resource \"null_resource\" \"foo\" {\n\
        \      - id = (known after apply)\n\
        \    }\n\n\
         Plan: 3 to add, 0 to change, 0 to destroy."
      in
      let plan_diff =
        "Terraform used the selected providers to generate the following execution\n\
         plan. Resource actions are indicated with the following symbols:\n\
         +   create\n\n\
         Terraform will perform the following actions:\n\n\
        \  # null_resource.bar will be created\n\
         +   resource \"null_resource\" \"bar\" {\n\
         +       id = (known after apply)\n\
        \    }\n\n\
        \  # null_resource.baz will be created\n\
         +   resource \"null_resource\" \"baz\" {\n\
         +       id = (known after apply)\n\
        \    }\n\n\
        \  # null_resource.foo will be created\n\
         !   resource \"null_resource\" \"foo\" {\n\
         -       id = (known after apply)\n\
        \    }\n\n\
         Plan: 3 to add, 0 to change, 0 to destroy."
      in
      assert (CCString.equal plan_diff (Terrat_plan_diff.transform plan_text)))

let test = Oth.parallel [ test_simple ]

let () =
  Random.self_init ();
  Oth.run test
