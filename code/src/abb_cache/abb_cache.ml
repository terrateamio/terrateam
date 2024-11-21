module Make (Abb : Abb_intf.S) = struct
  module Fut_comb = Abb_future_combinators.Make (Abb.Future)

  module type S = sig
    type k
    type args
    type v
    type err

    val fetch : args -> (v, err) result Abb.Future.t
    val equal_k : k -> k -> bool
    val weight : v -> int
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
      capacity : int;
    }

    module Make (M : S) = struct
      module Lru_k = struct
        type t = M.k

        let equal = M.equal_k
        let hash = Hashtbl.hash
      end

      module Lru_v = struct
        type t = (M.v, M.err) result Abb.Future.t

        let weight v =
          match Abb.Future.state v with
          | `Det (Ok v) ->
              let weight = M.weight v in
              assert (weight >= 0);
              CCInt.max 1 weight
          | `Undet -> 1
          | `Det (Error _) | `Aborted | `Exn _ ->
              (* All errors are 1, but errors are removed immediately so this is
                 really more of a dummy value. *)
              1
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

      let create opts = { opts; cache = Lru.create opts.capacity }

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
      on_evict : unit -> unit;
      duration : Duration.t;
      capacity : int;
    }

    module Make (M : S) = struct
      module Expiration_index = CCMap.Make (struct
        type t = float [@@deriving ord]
      end)

      type nonrec opts = opts

      type t = {
        opts : opts;
        cache : (M.k, (M.v, M.err) result Abb.Future.t * float) Hashtbl.t;
        mutable expiration_index : (M.k * int) list Expiration_index.t;
        mutable load : int;
      }

      type k = M.k
      type args = M.args
      type v = M.v
      type err = M.err

      let evict_entries expiration weights t =
        t.expiration_index <- Expiration_index.remove expiration t.expiration_index;
        CCList.iter
          (fun (k, weight) ->
            Hashtbl.remove t.cache k;
            t.load <- t.load - weight;
            t.opts.on_evict ())
          weights

      let rec maybe_evict now t =
        if t.load > t.opts.capacity then
          match Expiration_index.min_binding_opt t.expiration_index with
          | Some (expiration, weights) ->
              evict_entries expiration weights t;
              maybe_evict now t
          | None -> ()
        else
          match Expiration_index.min_binding_opt t.expiration_index with
          | Some (expiration, weights) when expiration < now ->
              evict_entries expiration weights t;
              maybe_evict now t
          | Some _ | None -> ()

      let create opts =
        { opts; cache = Hashtbl.create 10; expiration_index = Expiration_index.empty; load = 0 }

      let fetch t k args =
        let open Abb.Future.Infix_monad in
        Abb.Sys.monotonic ()
        >>= fun now ->
        maybe_evict now t;
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
                  | Ok v as r ->
                      let weight = CCInt.max 1 (M.weight v) in
                      t.expiration_index <-
                        Expiration_index.add_to_list
                          (now +. Duration.to_f t.opts.duration)
                          (k, weight)
                          t.expiration_index;
                      t.load <- t.load + weight;
                      Abb.Future.return r
                  | Error _ as err ->
                      Hashtbl.remove t.cache k;
                      Abb.Future.return err)
            in
            Hashtbl.replace t.cache k (ret, now +. Duration.to_f t.opts.duration);
            Abb.Future.fork ret >>= fun _ -> ret
    end
  end
end
