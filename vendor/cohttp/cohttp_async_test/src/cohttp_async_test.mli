open Async_kernel

include
  Cohttp_test.S
    with type 'a io = 'a Deferred.t
     and type body = Cohttp_async.Body.t
     and type ic = Async_unix.Reader.t
     and type oc = Async_unix.Writer.t

val run_async_tests : OUnit.test io -> OUnit.test_result list Deferred.t
