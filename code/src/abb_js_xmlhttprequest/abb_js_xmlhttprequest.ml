let state = Abb_fut.State.create ()

let send ?body ~meth ~url () =
  let req = XmlHttpRequest.create () in
  let promise = Abb_fut.Promise.create () in
  req##.onload := Dom.handler
      (fun _ ->
         ignore (Abb_fut.run_with_state
                   (Abb_fut.Promise.set promise (Js.to_string req##.responseText))
                   state);
         Js._true);
  req##_open (Js.string meth) (Js.string url) Js._true;
  req##send (Js.Opt.map (Js.Opt.option body) Js.string);
  Abb_fut.Promise.future promise
