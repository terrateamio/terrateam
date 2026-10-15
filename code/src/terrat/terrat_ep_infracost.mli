(** Where the Infracost CLI requests get their answer. [Proxy] forwards them to an Infracost pricing
    API. [Price_book] serves them from the pool of the price-book database. *)
type backend =
  | Proxy of Terrat_config.Infracost.proxy
  | Price_book of Terrat_storage.t

(** The backend of the Infracost the configuration names, or [None] when cost estimation is off. A
    price book gets a pool of its own. *)
val create_backend : Terrat_config.t -> backend option Abb.Future.t

(** Serve the Infracost CLI. The first parameter is [None] when cost estimation is off. The last
    parameter is the path under [/infracost/]: [graphql] or [event]. *)
val post : backend option -> Terrat_storage.t -> string -> Brtl_rtng.Handler.t
