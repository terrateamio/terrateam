let timer_test =
  Oth.test ~desc:"Simple timer test" ~name:"Timer Test #1" (fun _ ->
      let kq = Kqueue.create () in
      let timer = Kqueue.Change.Filter.Timer.{ id = 1; unit = Unit.to_t Unit.Seconds; time = 1 } in
      let kevent =
        Kqueue.Change.(Filter.to_kevent (Action.to_t [ Action.Flag.Add ]) (Filter.Timer timer))
      in
      ignore
        (Kqueue.kevent
           kq
           ~changelist:(Kqueue.Eventlist.of_list [ kevent ])
           ~eventlist:Kqueue.Eventlist.null
           ~timeout:None);
      let eventlist = Kqueue.Eventlist.create 1 in
      let ret =
        Kqueue.kevent
          kq
          ~changelist:Kqueue.Eventlist.null
          ~eventlist
          ~timeout:(Some (Kqueue.Timeout.create ~sec:5 ~nsec:0))
      in
      assert (ret = 1))

let () =
  Random.self_init ();
  Oth.(run (parallel [ timer_test ]))
