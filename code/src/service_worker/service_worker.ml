module Js = Js_of_ocaml.Js

module Blob = struct
  module J = struct
    class type t =
      object
        method slice : int -> int -> t Js.t Js.meth

        method size : int Js.readonly_prop
      end
  end

  type t = J.t Js.t

  let slice (t : t) ~start ~stop = t##slice start stop

  let size (t : t) = t##.size
end

module Headers = struct
  module J = struct
    class type t =
      object
        method get : Js.js_string Js.t -> Js.js_string Js.t Js.opt Js.meth

        method set : Js.js_string Js.t -> Js.js_string Js.t -> unit Js.meth
      end

    let constr : (t Js.t -> t Js.t) Js.constr = Js.Unsafe.global##._Headers
  end

  type t = J.t Js.t

  let create (t : t) = new%js J.constr t

  let get (t : t) name = CCOpt.map Js.to_string (Js.Opt.to_option (t##get (Js.string name)))

  let set (t : t) name value = t##set (Js.string name) (Js.string value)
end

module Request = struct
  module J = struct
    class type t =
      object
        method method_ : Js.js_string Js.t Js.readonly_prop

        method url : Js.js_string Js.t Js.readonly_prop

        method headers : Headers.t Js.readonly_prop
      end
  end

  type t = J.t Js.t

  let url (t : t) = Js.to_string t##.url

  let meth (t : t) = Js.to_string t##.method_

  let headers (t : t) = t##.headers
end

module Response = struct
  module J = struct
    class type t =
      object
        method clone : t Js.t Js.meth

        method blob : Blob.t Abb_fut_js.promise Js.t Js.meth

        method status : int Js.readonly_prop

        method headers : Headers.t Js.readonly_prop
      end

    class type opts =
      object
        method headers : Headers.t Js.readonly_prop

        method status : int Js.readonly_prop
      end

    let constr : (Blob.t -> opts Js.t -> t Js.t) Js.constr = Js.Unsafe.global##._Response
  end

  type t = J.t Js.t

  let create ~body ~headers ~status =
    new%js J.constr
      body
      (object%js
         val headers = headers

         val status = status
      end)

  let clone (t : t) = t##clone

  let blob (t : t) = Abb_fut_js.unsafe_of_promise t##blob

  let status (t : t) = t##.status

  let headers (t : t) = t##.headers
end

module Background_fetch_registration = struct
  module Record = struct
    module J = struct
      class type t =
        object
          method id : Js.js_string Js.t Js.readonly_prop

          method request : Request.t Js.readonly_prop

          method responseReady : Response.t Abb_fut_js.promise Js.t Js.readonly_prop
        end
    end

    type t = J.t Js.t

    let id (t : t) = Js.to_string t##.id

    let request (t : t) = t##.request

    let response_ready (t : t) = Abb_fut_js.unsafe_of_promise t##.responseReady
  end

  module J = struct
    class type t =
      object
        method id : Js.js_string Js.t Js.readonly_prop

        method uploadTotal : int Js.readonly_prop

        method uploaded : int Js.readonly_prop

        method downloadTotal : int Js.readonly_prop

        method downloaded : int Js.readonly_prop

        method result : Js.js_string Js.t Js.readonly_prop

        method failureReason : Js.js_string Js.t Js.readonly_prop

        method recordsAvailable : bool Js.t Js.readonly_prop

        method abort : bool Js.t Abb_fut_js.promise Js.t Js.meth

        method matchAll : Record.t Js.js_array Js.t Abb_fut_js.promise Js.t Js.meth

        method match_ : Request.t -> Record.t Js.optdef Abb_fut_js.promise Js.t Js.meth

        method addEventListener :
          Js.js_string Js.t -> ('self Js.t, unit -> unit) Js.meth_callback -> unit Js.meth

        method removeEventListener : Js.js_string Js.t -> unit Js.meth
      end
  end

  type t = J.t Js.t

  let id (t : t) = Js.to_string t##.id

  let upload_total (t : t) = t##.uploadTotal

  let uploaded (t : t) = t##.uploaded

  let download_total (t : t) = t##.downloadTotal

  let downloaded (t : t) = t##.downloaded

  let result (t : t) =
    match Js.to_string t##.result with
      | "success" -> `Success
      | "failure" -> `Failure (Js.to_string t##.failureReason)
      | _         -> (* Assuming anything else is active.  Could be a bad decision *) `Active

  let records_available (t : t) = Js.to_bool t##.recordsAvailable

  let abort (t : t) =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise t##abort >>| Js.to_bool

  let match_all (t : t) =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise t##matchAll
    >>| fun matches -> matches |> Js.to_array |> Array.to_list

  let match_ (t : t) req =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise (t##match_ req) >>| Js.Optdef.to_option

  let set_onprogress (t : t) cb =
    t##addEventListener (Js.string "progress") (Js.wrap_callback (fun () -> Abb_fut_js.run (cb ())))

  let rem_onprogress (t : t) = t##removeEventListener (Js.string "progress")
end

module Background_fetch_event = struct
  module J = struct
    class type t =
      object
        method waitUntil : unit Abb_fut_js.promise Js.t -> unit Js.meth

        method registration : Background_fetch_registration.t Js.readonly_prop
      end
  end

  type t = J.t Js.t

  let wait_until (t : t) fut =
    Abb_fut_js.run fut;
    t##waitUntil (Abb_fut_js.unsafe_to_promise fut)

  let registration (t : t) = t##.registration

  let update_ui (t : t) = raise (Failure "nyi")
end

module Registration = struct
  module Icon_def = struct
    module J = struct
      class type t =
        object
          method sizes : Js.js_string Js.t Js.readonly_prop

          method src : Js.js_string Js.t Js.readonly_prop

          method type_ : Js.js_string Js.t Js.optdef Js.readonly_prop
        end
    end

    type t = J.t Js.t

    let create ?typ ~sizes src =
      object%js
        val sizes = Js.string sizes

        val src = Js.string src

        val type_ = Js.Optdef.option (CCOpt.map Js.string typ)
      end
  end

  module Options = struct
    module J = struct
      class type t =
        object
          method title : Js.js_string Js.t Js.readonly_prop

          method icons : Icon_def.t Js.js_array Js.t Js.readonly_prop

          method downloadTotal : int Js.readonly_prop
        end
    end

    type t = J.t Js.t

    let create ~title ~icons ~total_size =
      object%js
        val title = Js.string title

        val icons = icons |> Array.of_list |> Js.array

        val downloadTotal = total_size
      end
  end

  module J = struct
    class type bf =
      object
        method fetch :
          Js.js_string Js.t ->
          Js.js_string Js.t Js.js_array Js.t ->
          Options.t ->
          Background_fetch_registration.t Abb_fut_js.promise Js.t Js.meth

        method getIds : Js.js_string Js.t Js.js_array Js.t Abb_fut_js.promise Js.t Js.meth

        method get :
          Js.js_string Js.t ->
          Background_fetch_registration.t Js.optdef Abb_fut_js.promise Js.t Js.meth
      end

    class type t =
      object
        method installing : bool Js.t Js.readonly_prop

        method backgroundFetch : bf Js.t Js.readonly_prop
      end
  end

  type t = J.t Js.t

  let installing (t : t) = Js.to_bool t##.installing

  let background_fetch (t : t) id requests options =
    Abb_fut_js.unsafe_of_promise
      (t##.backgroundFetch##fetch
         (Js.string id)
         (requests |> List.map Js.string |> Array.of_list |> Js.array)
         options)

  let background_fetch_ids (t : t) =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise t##.backgroundFetch##getIds
    >>| fun ids -> ids |> Js.to_array |> Array.to_list |> List.map Js.to_string

  let background_fetch_get (t : t) id =
    Abb_fut_js.unsafe_of_promise (t##.backgroundFetch##get (Js.string id))
end

module Service_worker_container = struct
  module J = struct
    class type register_opts =
      object
        method scope : Js.js_string Js.t Js.readonly_prop
      end

    class type t =
      object
        method register :
          Js.js_string Js.t -> register_opts Js.t -> Registration.t Abb_fut_js.promise Js.t Js.meth

        method ready : Registration.t Abb_fut_js.promise Js.t Js.readonly_prop
      end
  end

  type t = J.t Js.t

  let register (t : t) ~scope worker_path =
    let promise : Registration.t Abb_fut_js.promise Js.t =
      t##register
        (Js.string worker_path)
        (object%js
           val scope = Js.string scope
        end)
    in
    Abb_fut_js.unsafe_of_promise promise

  let ready (t : t) = Abb_fut_js.unsafe_of_promise t##.ready
end

module Cache = struct
  module J = struct
    class type t =
      object
        method addAll : Js.js_string Js.t Js.js_array Js.t -> unit Abb_fut_js.promise Js.t Js.meth

        method put : Request.t -> Response.t -> unit Abb_fut_js.promise Js.t Js.meth

        method delete : Js.js_string Js.t -> bool Js.t Abb_fut_js.promise Js.t Js.meth
      end
  end

  type t = J.t Js.t

  let add_all (t : t) items =
    Abb_fut_js.unsafe_of_promise
      (t##addAll (items |> CCList.map Js.string |> CCArray.of_list |> Js.array))

  let put (t : t) request response = Abb_fut_js.unsafe_of_promise (t##put request response)

  let delete (t : t) url =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise (t##delete (Js.string url)) >>| Js.to_bool
end

module Cache_storage = struct
  module J = struct
    class type t =
      object
        method open_ : Js.js_string Js.t -> Cache.t Abb_fut_js.promise Js.t Js.meth

        method match_ : Request.t -> Response.t Js.optdef Abb_fut_js.promise Js.t Js.meth

        method match_string :
          Js.js_string Js.t -> Response.t Js.optdef Abb_fut_js.promise Js.t Js.meth

        method keys : Js.js_string Js.t Js.js_array Js.t Abb_fut_js.promise Js.t Js.meth

        method delete : Js.js_string Js.t -> unit Abb_fut_js.promise Js.t Js.meth
      end
  end

  type t = J.t Js.t

  let open_ t name = Abb_fut_js.unsafe_of_promise (t##open_ (Js.string name))

  let match_ (t : t) request = Abb_fut_js.unsafe_of_promise (t##match_ request)

  let match_str (t : t) str = Abb_fut_js.unsafe_of_promise (t##match_string (Js.string str))

  let keys (t : t) =
    let open Abb_fut_js.Infix_monad in
    Abb_fut_js.unsafe_of_promise t##keys
    >>| fun keys -> CCList.map Js.to_string (Array.to_list (Js.to_array keys))

  let delete (t : t) n = Abb_fut_js.unsafe_of_promise (t##delete (Js.string n))
end

module Global_scope = struct
  module Event = struct
    module J = struct
      class type t =
        object
          method waitUntil : unit Abb_fut_js.promise Js.t -> unit Js.meth
        end
    end

    type t = J.t Js.t

    let wait_until (t : t) fut =
      Abb_fut_js.run fut;
      t##waitUntil (Abb_fut_js.unsafe_to_promise fut)
  end

  module Install_event = struct
    module J = struct
      class type t =
        object
          method waitUntil : unit Abb_fut_js.promise Js.t -> unit Js.meth
        end
    end

    type t = J.t Js.t

    let wait_until (t : t) fut =
      Abb_fut_js.run fut;
      t##waitUntil (Abb_fut_js.unsafe_to_promise fut)
  end

  module Fetch_event = struct
    module J = struct
      class type t =
        object
          method request : Request.t Js.readonly_prop

          method respondWith : Response.t Abb_fut_js.promise Js.t -> unit Js.meth
        end
    end

    type t = J.t Js.t

    let request (t : t) = t##.request

    let respond_with (t : t) fut =
      Abb_fut_js.run fut;
      t##respondWith (Abb_fut_js.unsafe_to_promise fut)
  end

  module Clients = struct
    module J = struct
      class type t =
        object
          method claim : unit Abb_fut_js.promise Js.t Js.meth
        end
    end

    type t = J.t Js.t

    let claim (t : t) = Abb_fut_js.unsafe_of_promise t##claim
  end

  module J = struct
    class type t =
      object
        method skipWaiting : unit Abb_fut_js.promise Js.t Js.meth

        method oninstall :
          ('self Js.t, Install_event.t -> unit) Js.meth_callback Js.opt Js.writeonly_prop

        method onactivate : ('self Js.t, Event.t -> unit) Js.meth_callback Js.opt Js.writeonly_prop

        method onfetch :
          ('self Js.t, Fetch_event.t -> unit) Js.meth_callback Js.opt Js.writeonly_prop
      end
  end

  type t = J.t Js.t

  let self = Js.Unsafe.global##.self

  let caches = Js.Unsafe.global##.caches

  let clients = Js.Unsafe.global##.clients

  let fetch request =
    Abb_fut_js.unsafe_of_promise
      (Js.Unsafe.fun_call Js.Unsafe.global##.fetch [| Js.Unsafe.inject request |])

  let skip_waiting (t : t) = ignore t##skipWaiting

  let set_oninstall (t : t) cb = t##.oninstall := Js.some (Js.wrap_callback cb)

  let set_onactivate (t : t) cb = t##.onactivate := Js.some (Js.wrap_callback cb)

  let set_onfetch (t : t) cb = t##.onfetch := Js.some (Js.wrap_callback cb)
end

module Event_name = struct
  type 'a t = string
end

let background_fetch_success = "backgroundfetchsuccess"

let service_worker () =
  let service_worker : Service_worker_container.t Js.optdef =
    Js.Unsafe.js_expr "navigator.serviceWorker"
  in
  Js.Optdef.to_option service_worker

let add_event_listener : 'a Event_name.t -> ('a -> unit) -> unit =
 fun name cb ->
  let f : Js.js_string Js.t -> ('a -> unit) Js.callback -> unit =
    Js.Unsafe.global##.addEventListener
  in
  f (Js.string name) (Js.wrap_callback (fun v -> cb v))
