module Monad = struct
  type +'a t = 'a
end

module T = struct
  let time = Unix.gettimeofday

  let monotonic () = Mtime.Span.to_s (Mtime_clock.elapsed ())
end

module Time = Abb_time.Make (Monad) (T)

let wall_diff_prop =
  Oth.test ~desc:"Wall clock diff property" ~name:"Wall diff property" (fun _ ->
      let t1 = Time.Wall.now () in
      for i = 0 to Random.int 100000 do
        ()
      done;
      let t2 = Time.Wall.now () in
      let diff = Time.Wall.diff t1 t2 in
      let add_t2 = Time.Wall.add t1 diff in
      let diff' = abs_float (Abb_time.Span.to_sec (Time.Wall.diff t2 add_t2)) in
      assert (Time.Wall.(diff' <= epsilon_float)))

let mono_diff_prop =
  Oth.test ~desc:"Monotonic diff property" ~name:"Monotonic diff property" (fun _ ->
      let t1 = Time.Mono.now () in
      for i = 0 to Random.int 100000 do
        ()
      done;
      let t2 = Time.Mono.now () in
      let diff = Time.Mono.diff t1 t2 in
      let add_t2 = Time.Mono.add t1 diff in
      let diff' = abs_float (Abb_time.Span.to_sec (Time.Mono.diff t2 add_t2)) in
      assert (Time.Mono.(diff' <= epsilon_float)))

let () =
  Random.self_init ();
  Oth.(run (parallel [ loop 10 wall_diff_prop; loop 10 mono_diff_prop ]))
