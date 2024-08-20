module Fut_comb = Abb_future_combinators.Make (Abb.Future)

module type S = sig
  type k
  type args
  type v
  type err

  val fetch : args -> (v, err) result Abb.Future.t
  val equal_k : k -> k -> bool
end

module type SRC = sig
  type opts
  type t
  type k
  type args
  type v
  type err

  val create : opts -> t
  val fetch : t -> k -> args -> (v, err) result Abb.Future.t
end

module Passthrough = struct
  module Make (M : S) = struct
    type opts = unit
    type t = unit
    type k = M.k
    type args = M.args
    type v = M.v
    type err = M.err

    let create () = ()
    let fetch () _ = M.fetch
  end
end

module Memo = struct
  type opts = {
    on_hit : unit -> unit;
    on_miss : unit -> unit;
  }

  module Make (M : S) = struct
    type nonrec opts = opts

    type t = {
      opts : opts;
      cache : (M.k, (M.v, M.err) result Abb.Future.t) Hashtbl.t;
    }

    type k = M.k
    type args = M.args
    type v = M.v
    type err = M.err

    let create opts = { opts; cache = Hashtbl.create 10 }

    let fetch t k args =
      match CCHashtbl.get t.cache k with
      | Some v ->
          t.opts.on_hit ();
          v
      | None ->
          let open Abb.Future.Infix_monad in
          t.opts.on_miss ();
          let ret =
            Fut_comb.guard (fun () ->
                M.fetch args
                >>= function
                | Ok _ as r -> Abb.Future.return r
                | Error _ as err ->
                    Hashtbl.remove t.cache k;
                    Abb.Future.return err)
          in
          Hashtbl.replace t.cache k ret;
          Abb.Future.fork ret >>= fun _ -> ret
  end
end

module Lru = struct
  type opts = {
    on_hit : unit -> unit;
    on_miss : unit -> unit;
    size : int;
  }

  module Make (M : S) = struct
    module Lru_k = struct
      type t = M.k

      let equal = M.equal_k
      let hash = Hashtbl.hash
    end

    module Lru_v = struct
      type t = (M.v, M.err) result Abb.Future.t

      let weight _ = 1
    end

    module Lru = Lru.M.Make (Lru_k) (Lru_v)

    type nonrec opts = opts

    type t = {
      opts : opts;
      cache : Lru.t;
    }

    type k = M.k
    type args = M.args
    type v = M.v
    type err = M.err

    let create opts = { opts; cache = Lru.create opts.size }

    let fetch t k args =
      match Lru.find k t.cache with
      | Some ret ->
          t.opts.on_hit ();
          Lru.promote k t.cache;
          Lru.trim t.cache;
          ret
      | None ->
          let open Abb.Future.Infix_monad in
          t.opts.on_miss ();
          let ret =
            Fut_comb.guard (fun () ->
                M.fetch args
                >>= function
                | Ok _ as r -> Abb.Future.return r
                | Error _ as err ->
                    Lru.remove k t.cache;
                    Abb.Future.return err)
          in
          Lru.add k ret t.cache;
          Lru.trim t.cache;
          Abb.Future.fork ret >>= fun _ -> ret
  end
end

module Expiring = struct
  type opts = {
    on_hit : unit -> unit;
    on_miss : unit -> unit;
    duration : Duration.t;
    size : int;
  }

  module Make (M : S) = struct
    type nonrec opts = opts

    type t = {
      opts : opts;
      cache : (M.k, (M.v, M.err) result Abb.Future.t * float) Hashtbl.t;
    }

    type k = M.k
    type args = M.args
    type v = M.v
    type err = M.err

    let create opts = { opts; cache = Hashtbl.create 10 }

    let fetch t k args =
      let open Abb.Future.Infix_monad in
      Abb.Sys.monotonic ()
      >>= fun now ->
      if Hashtbl.length t.cache > t.opts.size then
        Hashtbl.filter_map_inplace
          (fun _ ((_, expiration) as v) -> if expiration < now then None else Some v)
          t.cache;
      match CCHashtbl.get t.cache k with
      | Some (v, expiration) when now < expiration ->
          t.opts.on_hit ();
          v
      | Some _ | None ->
          t.opts.on_miss ();
          let ret =
            Fut_comb.guard (fun () ->
                M.fetch args
                >>= function
                | Ok _ as r -> Abb.Future.return r
                | Error _ as err ->
                    Hashtbl.remove t.cache k;
                    Abb.Future.return err)
          in
          Hashtbl.replace t.cache k (ret, now +. Duration.to_f t.opts.duration);
          Abb.Future.fork ret >>= fun _ -> ret
  end
end
