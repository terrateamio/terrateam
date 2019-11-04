include Abb_fut.Make (struct
  type t = unit
end)

let dummy_state = Abb_fut.State.create ()

let run t = ignore (run_with_state t dummy_state)
