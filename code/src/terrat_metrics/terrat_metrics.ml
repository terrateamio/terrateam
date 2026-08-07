let namespace = "terrat"

let errors_total =
  let help = "Number of errors" in
  let family =
    Prmths.Counter.v_labels ~label_names:[ "module"; "type" ] ~help ~namespace "errors_total"
  in
  fun ~m ~t -> Prmths.Counter.labels family [ m; t ]

let apply_total =
  let help = "Number of apply operations initiated" in
  let family = Prmths.Counter.v_labels ~label_names:[ "force" ] ~help ~namespace "apply_total" in
  fun ~force -> Prmths.Counter.labels family [ force ]
