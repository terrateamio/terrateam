module Choice = struct
  type 'a t = {
    value : 'a;
    els : Brtl_js2.Brr.El.t list;
    path : string;
  }

  let create ~value els path = { value; els; path }
end

let run ~eq ~choices routes state =
  Brtl_js2.Note.S.map ~eq:( == ) (fun mtch ->
      let choice_selected =
        match mtch with
        | Some v -> eq (Brtl_js2_rtng.Match.apply v)
        | None -> CCFun.const false
      in
      CCList.map
        (fun choice ->
          let el =
            Brtl_js2.Brr.El.div
              ~at:
                [
                  Brtl_js2.Brr.At.(
                    if' (choice_selected choice.Choice.value) (class' (Jstr.v "selected")));
                ]
              choice.Choice.els
          in
          ignore
            Brtl_js2.Brr.(
              Ev.listen
                Ev.click
                (fun _ -> Brtl_js2.Router.navigate (Brtl_js2.State.router state) choice.Choice.path)
                (El.as_target el));
          el)
        choices)
  @@ Brtl_js2.Note.S.map
       ~eq:(fun m1 m2 ->
         match (m1, m2) with
         | Some m1, Some m2 -> Brtl_js2_rtng.Match.equal m1 m2
         | None, None -> true
         | _, _ -> false)
       (Brtl_js2_rtng.first_match ~must_consume_path:false routes)
       Brtl_js2.(Router.uri (State.router state))
