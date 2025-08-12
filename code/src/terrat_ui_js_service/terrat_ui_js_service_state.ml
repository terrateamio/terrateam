module Make (Vcs : Terrat_ui_js_service_vcs.S) = struct
  type 'v t = {
    vcs : Vcs.t;
    v : 'v;
  }

  type v = {
    installations : Vcs.Installation.t list;
    notify : Terrat_ui_js_service_comp_notifications.Notice.t Brtl_js2.Note.E.send;
    selected_installation : Vcs.Installation.t;
    server_config : Vcs.Server_config.t;
    user : Vcs.User.t;
  }
end
