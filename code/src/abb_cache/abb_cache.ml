module Make (Abb : Abb_intf.S) = struct
  module Abb_io_file = Abb_io_file.Make (Abb)
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

  module Filesystem = struct
    type cache_err =
      [ Abb_io_file.with_file_err
      | Abb_intf.Errors.write
      | Abb_intf.Errors.read
      ]
    [@@deriving show]

    type opts = {
      on_hit : unit -> unit;
      on_miss : unit -> unit;
      on_evict : unit -> unit;
      path : string;
    }

    module Make (M : S with type k = string and type v = string) = struct
      type nonrec opts = opts
      type k = M.k
      type args = M.args
      type v = M.v

      type err =
        [ `Fetch_err of M.err
        | `Cache_err of cache_err
        ]

      type t = {
        opts : opts;
        cache : (M.k, (M.v, err) result Abb.Future.t) Hashtbl.t;
      }

      let create opts =
        if not (Sys.file_exists opts.path) then Sys.mkdir opts.path 0o700;
        { opts; cache = Hashtbl.create 10 }

      let id_of_k = CCFun.(Digest.string %> Digest.to_hex)

      let fetch' t k filename args =
        let open Abb.Future.Infix_monad in
        let run =
          Fut_comb.guard (fun () ->
              M.fetch args
              >>= function
              | Ok v as r -> (
                  Abb_io_file.write_file ~fname:(filename ^ ".tmp") v
                  >>= function
                  | Ok () ->
                      Abb_io_file.write_file ~fname:(filename ^ ".key") k
                      >>= fun _ ->
                      Abb.File.rename ~src:(filename ^ ".tmp") ~dst:filename
                      >>= fun _ ->
                      Hashtbl.remove t.cache k;
                      Abb.Future.return r
                  | Error (#Abb_io_file.with_file_err as err) ->
                      Hashtbl.remove t.cache k;
                      Abb.Future.return (Error (`Cache_err err))
                  | Error (#Abb_intf.Errors.write as err) ->
                      Hashtbl.remove t.cache k;
                      Abb.Future.return (Error (`Cache_err err)))
              | Error err ->
                  Hashtbl.remove t.cache k;
                  Abb.Future.return (Error (`Fetch_err err)))
        in
        Hashtbl.replace t.cache k run;
        Abb.Future.fork run >>= fun _ -> run

      let fetch t k args =
        let open Abb.Future.Infix_monad in
        let filename = Filename.concat t.opts.path @@ id_of_k k in
        if Sys.file_exists filename then
          Abb_io_file.read_file filename
          >>= function
          | Ok contents ->
              t.opts.on_hit ();
              Abb.Future.return (Ok contents)
          | Error (#Abb_intf.Errors.read as err) -> Abb.Future.return (Error (`Cache_err err))
          | Error (#Abb_io_file.with_file_err as err) -> Abb.Future.return (Error (`Cache_err err))
        else (
          t.opts.on_miss ();
          fetch' t k filename args)
    end
  end
end
