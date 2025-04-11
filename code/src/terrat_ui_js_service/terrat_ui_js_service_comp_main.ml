type create_err = [ `Error ] [@@deriving show]

module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  type 'a t = {
    vcs : Vcs.t;
    v : 'a;
  }

  let vcs t = t.vcs
  let create vcs = Abb_js.Future.return (Ok { vcs; v = () })
  let run state = raise (Failure "nyi")
end
