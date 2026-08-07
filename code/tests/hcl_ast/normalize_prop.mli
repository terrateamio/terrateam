(** Randomized ([qcheck]) coverage of the invariants of [Hcl_ast.Normalize]: meaning-preserving
    surface differences must converge to one normalized AST, and meaning-changing differences must
    not. Complements the hand-written examples in [test.ml], which pin specific cases. *)

val tests : Oth.Test.t list
