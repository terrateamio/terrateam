(** Tests for [Abb.Task.run ~pinned:false]: the unpinned execution model where the task body and its
    async-op callbacks run on worker domains in the scheduler's thread pool.

    Unpinned tasks exercise the cross-domain hand-off paths in the scheduler (op queue, per-task
    lock, post-callback delivery) so this module is the strongest signal that the plumbing is
    correct. Missed locking, stale chain data, or watcher-fires from the wrong domain show up here
    first. *)
module Make (_ : Abb_intf.S) : sig
  val test : Oth.Test.t
end
