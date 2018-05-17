open Sexplib

val component_of_sexp : Sexp.t -> Uri.component
val sexp_of_component : Uri.component -> Sexp.t
val t_of_sexp : Sexp.t -> Uri.t
val sexp_of_t : Uri.t -> Sexp.t
