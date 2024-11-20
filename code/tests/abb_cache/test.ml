module Abb = Abb_scheduler_select
module Oth_abb = Oth_abb.Make (Abb)
module Abb_cache = Abb_cache.Make (Abb)

let test_expiring_cache =
  Oth_abb.test ~name:"Expiring cache" (fun () ->
      let open Abb.Future.Infix_monad in
      let module C = Abb_cache.Expiring.Make (struct
        type k = string
        type args = int ref * string
        type v = string
        type err = [ `Error ]

        let fetch (r, v) =
          incr r;
          Abb.Future.return (Ok v)

        let equal_k = CCString.equal
        let weight = CCString.length
      end) in
      let count = ref 0 in
      let k1 = "key1" in
      let k2 = "key2" in
      let v1 = "value1" in
      let v2 = "value2" in
      let cache =
        C.create
          {
            Abb_cache.Expiring.on_hit = CCFun.const ();
            on_miss = CCFun.const ();
            on_evict = CCFun.const ();
            duration = Duration.of_sec 1;
            capacity = CCString.length (v1 ^ v2);
          }
      in
      C.fetch cache k1 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k2 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 2);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 2);
      Abb.Future.return ())

let test_expiring_cache_expiration_eviction =
  Oth_abb.test ~name:"Expiring cache expiration eviction" (fun () ->
      let open Abb.Future.Infix_monad in
      let module C = Abb_cache.Expiring.Make (struct
        type k = string
        type args = int ref * string
        type v = string
        type err = [ `Error ]

        let fetch (r, v) =
          incr r;
          Abb.Future.return (Ok v)

        let equal_k = CCString.equal
        let weight = CCString.length
      end) in
      let count = ref 0 in
      let k1 = "key1" in
      let k2 = "key2" in
      let v1 = "value1" in
      let v2 = "value2" in
      let cache =
        C.create
          {
            Abb_cache.Expiring.on_hit = CCFun.const ();
            on_miss = CCFun.const ();
            on_evict = CCFun.const ();
            duration = Duration.of_sec 1;
            capacity = CCString.length (v1 ^ v2);
          }
      in
      C.fetch cache k1 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k2 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 2);
      Abb.Sys.sleep 1.2
      >>= fun () ->
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 3);
      Abb.Future.return ())

let test_expiring_cache_capacity_eviction =
  Oth_abb.test ~name:"Expiring cache capacity eviction" (fun () ->
      let open Abb.Future.Infix_monad in
      let module C = Abb_cache.Expiring.Make (struct
        type k = string
        type args = int ref * string
        type v = string
        type err = [ `Error ]

        let fetch (r, v) =
          incr r;
          Abb.Future.return (Ok v)

        let equal_k = CCString.equal
        let weight = CCString.length
      end) in
      let count = ref 0 in
      let k1 = "key1" in
      let k2 = "key2" in
      let v1 = "value1" in
      let v2 = "value2" in
      let cache =
        C.create
          {
            Abb_cache.Expiring.on_hit = CCFun.const ();
            on_miss = CCFun.const ();
            on_evict = CCFun.const ();
            duration = Duration.of_sec 1;
            capacity = CCString.length v1;
          }
      in
      C.fetch cache k1 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k2 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 2);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 3);
      Abb.Future.return ())

let test_lru_cache =
  Oth_abb.test ~name:"LRU cache" (fun () ->
      let open Abb.Future.Infix_monad in
      let module C = Abb_cache.Lru.Make (struct
        type k = string
        type args = int ref * string
        type v = string
        type err = [ `Error ]

        let fetch (r, v) =
          incr r;
          Abb.Future.return (Ok v)

        let equal_k = CCString.equal
        let weight = CCString.length
      end) in
      let count = ref 0 in
      let k1 = "key1" in
      let k2 = "key2" in
      let v1 = "value1" in
      let v2 = "value2" in
      let cache =
        C.create
          {
            Abb_cache.Lru.on_hit = CCFun.const ();
            on_miss = CCFun.const ();
            capacity = CCString.length (v1 ^ v2);
          }
      in
      C.fetch cache k1 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k2 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 2);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 2);
      Abb.Future.return ())

let test_lru_cache_eviction =
  Oth_abb.test ~name:"LRU cache eviction" (fun () ->
      let open Abb.Future.Infix_monad in
      let module C = Abb_cache.Lru.Make (struct
        type k = string
        type args = int ref * string
        type v = string
        type err = [ `Error ]

        let fetch (r, v) =
          incr r;
          Abb.Future.return (Ok v)

        let equal_k = CCString.equal
        let weight = CCString.length
      end) in
      let count = ref 0 in
      let k1 = "key1" in
      let k2 = "key2" in
      let k3 = "key3" in
      let v1 = "value1" in
      let v2 = "value2" in
      let v3 = "value3" in
      let cache =
        C.create
          {
            Abb_cache.Lru.on_hit = CCFun.const ();
            on_miss = CCFun.const ();
            capacity = CCString.length (v1 ^ v2) + 3;
          }
      in
      C.fetch cache k1 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k2 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 2);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 2);
      C.fetch cache k3 (count, v3)
      >>= fun ret ->
      assert (ret = Ok v3);
      assert (!count = 3);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 3);
      C.fetch cache k2 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 4);
      Abb.Future.return ())

let test_lru_cache_capacity_eviction =
  Oth_abb.test ~name:"LRU cache capacity eviction" (fun () ->
      let open Abb.Future.Infix_monad in
      let module C = Abb_cache.Lru.Make (struct
        type k = string
        type args = int ref * string
        type v = string
        type err = [ `Error ]

        let fetch (r, v) =
          incr r;
          Abb.Future.return (Ok v)

        let equal_k = CCString.equal
        let weight = CCString.length
      end) in
      let count = ref 0 in
      let k1 = "key1" in
      let k2 = "key2" in
      let v1 = "value1" in
      let v2 = "value2" in
      let cache =
        C.create
          {
            Abb_cache.Lru.on_hit = CCFun.const ();
            on_miss = CCFun.const ();
            capacity = CCString.length v1;
          }
      in
      C.fetch cache k1 (count, v1)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v1);
      assert (!count = 1);
      C.fetch cache k2 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 2);
      C.fetch cache k1 (count, v2)
      >>= fun ret ->
      assert (ret = Ok v2);
      assert (!count = 3);
      Abb.Future.return ())

let test =
  Oth_abb.(
    to_sync_test
      (parallel
         [
           test_expiring_cache;
           test_expiring_cache_expiration_eviction;
           test_expiring_cache_capacity_eviction;
           test_lru_cache;
           test_lru_cache_eviction;
           test_lru_cache_capacity_eviction;
         ]))

let () =
  Random.self_init ();
  Oth.run test
