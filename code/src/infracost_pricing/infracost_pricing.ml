module Regex = struct
  type case =
    | Sensitive
    | Insensitive
  [@@deriving show, eq]

  type t = {
    pattern : string;
    case : case;
  }
  [@@deriving show, eq]

  let of_string s =
    match (CCString.find ~sub:"/" s, CCString.rfind ~sub:"/" s) with
    | first, last when first >= 0 && last >= first + 2 ->
        let flags = CCString.drop (last + 1) s in
        {
          pattern = CCString.sub s (first + 1) (last - first - 1);
          case = (if CCString.mem ~sub:"i" flags then Insensitive else Sensitive);
        }
    | _, _ -> { pattern = ""; case = Sensitive }
end

module Attribute_filter = struct
  type match_ =
    | Eq of string
    | Empty
    | Regex of Regex.t
    | Never
  [@@deriving show, eq]

  type t = {
    key : string;
    match_ : match_;
  }
  [@@deriving show, eq]
end

module Filter = struct
  type t = {
    vendor_name : string option;
    service : string option;
    product_family : string option;
    region : string option;
    sku : string option;
    attribute_filters : Attribute_filter.t list;
    purchase_option : string option;
    unit : string option;
    description : string option;
    description_regex : Regex.t option;
    start_usage_amount : string option;
    end_usage_amount : string option;
    term_length : string option;
    term_purchase_option : string option;
    term_offering_class : string option;
    currency : string;
    rate : string;
  }
  [@@deriving show, eq]
end

module Element = struct
  type t =
    | Probe
    | Query of Filter.t
  [@@deriving show, eq]
end

module Row = struct
  type cny_merge =
    | Merge_cny
    | No_cny_merge
  [@@deriving show, eq]

  type t = {
    product_hash : string;
    price_hash : string option;
    amount : string option;
    cny_amount : string option;
    start_usage_amount : string option;
    end_usage_amount : string option;
    cny_merge : cny_merge;
  }
  [@@deriving show, eq]
end

type err =
  [ `Bad_request_err
  | `Unsupported_currency_err
  ]
[@@deriving show, eq]

(* The shape of [attribute_filters] as the query reads it back out of a single
   jsonb parameter. *)
module Db_attribute_filter = struct
  type t = {
    kind : string;
    key : string;
    value : string option; [@default None]
  }
  [@@deriving to_yojson]

  let of_filter { Attribute_filter.key; match_ } =
    match match_ with
    | Attribute_filter.Eq value -> { kind = "eq"; key; value = Some value }
    | Attribute_filter.Empty -> { kind = "empty"; key; value = None }
    | Attribute_filter.Regex { Regex.pattern; case = Regex.Sensitive } ->
        { kind = "re"; key; value = Some pattern }
    | Attribute_filter.Regex { Regex.pattern; case = Regex.Insensitive } ->
        { kind = "re_ci"; key; value = Some pattern }
    | Attribute_filter.Never -> { kind = "never"; key; value = None }
end

type db_attribute_filters = Db_attribute_filter.t list [@@deriving to_yojson]

module Sql = struct
  let select_prices_sql = Mql_sql.read [%blob "sql/select_prices.sql"]

  let select_prices () =
    Pgsql_io.Typed_sql.(
      sql
      //
      (* productHash *)
      Ret.text
      //
      (* priceHash *)
      Ret.(option text)
      //
      (* amount *)
      Ret.(option text)
      //
      (* cny_amount *)
      Ret.(option text)
      //
      (* startUsageAmount *)
      Ret.(option text)
      //
      (* endUsageAmount *)
      Ret.(option text)
      //
      (* merges the CNY prices *)
      Ret.boolean
      /^ select_prices_sql
      /% Var.(option (text "vendor_name"))
      /% Var.(option (text "service"))
      /% Var.(option (text "product_family"))
      /% Var.(option (text "sku"))
      /% Var.(option (text "region"))
      /% Var.(option (text "instance_type"))
      /% Var.(option (text "operating_system"))
      /% Var.(option (text "capacity_status"))
      /% Var.(option (text "pre_installed_sw"))
      /% Var.json "attribute_filters"
      /% Var.text "rate"
      /% Var.text "cny_rate"
      /% Var.(option (text "purchase_option"))
      /% Var.(option (text "unit"))
      /% Var.(option (text "description"))
      /% Var.(option (text "description_regex"))
      /% Var.boolean "description_regex_ci"
      /% Var.(option (text "start_usage_amount"))
      /% Var.(option (text "end_usage_amount"))
      /% Var.(option (text "term_length"))
      /% Var.(option (text "term_purchase_option"))
      /% Var.(option (text "term_offering_class")))
end

(* The query text the CLI builds, with every white space character removed. The
   only free part is the name of the price field, which is the currency. *)
let query_prefix =
  "query($productFilter:ProductFilter!,$priceFilter:PriceFilter){products(filter:$productFilter){prices(filter:$priceFilter){priceHash"

let query_suffix = "}}}"

let is_currency_code s =
  CCString.length s = 3
  && CCString.for_all
       (function
         | 'A' .. 'Z' -> true
         | _ -> false)
       s

let currency_of_query query =
  let compact = CCString.filter (fun c -> not (Sln_string.is_whitespace c)) query in
  match compact with
  | "" -> Ok None
  | compact
    when CCString.prefix ~pre:query_prefix compact && CCString.suffix ~suf:query_suffix compact ->
      let start = CCString.length query_prefix in
      let len = CCString.length compact - start - CCString.length query_suffix in
      let code = if len > 0 then CCString.sub compact start len else "" in
      if is_currency_code code then Ok (Some code) else Error `Bad_request_err
  | _ -> Error `Bad_request_err

let attribute_filter_of_api
    { Terrat_api_components_infracost_attribute_filter.key; value; value_regex } =
  let match_ =
    match (value_regex, value) with
    | Some value_regex, _ when not (CCString.is_empty value_regex) ->
        Attribute_filter.Regex (Regex.of_string value_regex)
    | _, Some "" -> Attribute_filter.Empty
    | _, Some value -> Attribute_filter.Eq value
    | _, None -> Attribute_filter.Never
  in
  { Attribute_filter.key; match_ }

let filter_of_variables currency rate variables =
  let module Pf = Terrat_api_components_infracost_product_filter in
  let module Prf = Terrat_api_components_infracost_price_filter in
  let product =
    variables
    |> CCOption.flat_map (fun v -> v.Terrat_api_components_infracost_query_variables.productfilter)
    |> CCOption.get_or
         ~default:
           {
             Pf.attributefilters = None;
             productfamily = None;
             region = None;
             service = None;
             sku = None;
             vendorname = None;
           }
  in
  let price =
    variables
    |> CCOption.flat_map (fun v -> v.Terrat_api_components_infracost_query_variables.pricefilter)
    |> CCOption.get_or
         ~default:
           {
             Prf.description = None;
             description_regex = None;
             endusageamount = None;
             purchaseoption = None;
             startusageamount = None;
             termlength = None;
             termofferingclass = None;
             termpurchaseoption = None;
             unit = None;
           }
  in
  {
    Filter.vendor_name = product.Pf.vendorname;
    service = product.Pf.service;
    product_family = product.Pf.productfamily;
    region = product.Pf.region;
    sku = product.Pf.sku;
    attribute_filters =
      product.Pf.attributefilters
      |> CCOption.get_or ~default:[]
      |> CCList.map attribute_filter_of_api;
    purchase_option = price.Prf.purchaseoption;
    unit = price.Prf.unit;
    description = price.Prf.description;
    description_regex = CCOption.map Regex.of_string price.Prf.description_regex;
    start_usage_amount = price.Prf.startusageamount;
    end_usage_amount = price.Prf.endusageamount;
    term_length = price.Prf.termlength;
    term_purchase_option = price.Prf.termpurchaseoption;
    term_offering_class = price.Prf.termofferingclass;
    currency;
    rate;
  }

let decode_element json =
  let open CCResult.Infix in
  match Terrat_api_components_infracost_query.of_yojson json with
  | Ok { Terrat_api_components_infracost_query.query; variables } -> (
      currency_of_query query
      >>= function
      | None -> Ok Element.Probe
      | Some currency -> (
          match Infracost_pricing_currency.rate currency with
          | Some rate -> Ok (Element.Query (filter_of_variables currency rate variables))
          | None -> Error `Unsupported_currency_err))
  | Error _ -> Error `Bad_request_err

let decode = function
  | `List elements -> CCResult.map_l decode_element elements
  | `Null | `Bool _ | `Int _ | `Intlit _ | `Float _ | `String _ | `Assoc _ -> Error `Bad_request_err

(* Apollo answers an empty query with this element, and with status 200 because
   the batched path never sets a status of its own. *)
let probe_response =
  {
    Terrat_api_components_infracost_graphql_response.data = None;
    errors =
      Some
        [
          {
            Terrat_api_components_infracost_graphql_error.message =
              "GraphQL operations must contain a non-empty `query` or a `persistedQuery` extension.";
            extensions =
              {
                Terrat_api_components_infracost_graphql_error.Extensions.code =
                  "INTERNAL_SERVER_ERROR";
              };
          };
        ];
  }

module Product_map = CCMap.Make (CCString)

let group_by_product rows =
  rows
  |> CCList.fold_left
       (fun acc row ->
         Product_map.update
           row.Row.product_hash
           (function
             | Some prices -> Some (row :: prices)
             | None -> Some [ row ])
           acc)
       Product_map.empty
  |> Product_map.to_list
  |> CCList.map (fun (_, prices) -> CCList.rev prices)

let opt_string_equal = CCOption.equal CCString.equal

let is_cny_price = function
  | Some price_hash -> CCString.suffix ~suf:"-cny" price_hash
  | None -> false

let merge_cny rows =
  let cny, others = CCList.partition (fun r -> is_cny_price r.Row.price_hash) rows in
  let same_usage a b =
    opt_string_equal a.Row.start_usage_amount b.Row.start_usage_amount
    && opt_string_equal a.Row.end_usage_amount b.Row.end_usage_amount
  in
  let same_group a b = opt_string_equal a.Row.price_hash b.Row.price_hash && same_usage a b in
  let twins c o =
    opt_string_equal
      c.Row.price_hash
      (CCOption.map (fun price_hash -> price_hash ^ "-cny") o.Row.price_hash)
    && same_usage c o
  in
  let merges c =
    match (c.Row.amount, c.Row.cny_amount) with
    | None, Some _ -> CCList.length (CCList.filter (same_group c) cny) = 1
    | Some _, _ | None, None -> false
  in
  let merged =
    CCList.map
      (fun o ->
        match CCList.find_opt (fun c -> merges c && twins c o) cny with
        | Some c -> { o with Row.cny_amount = c.Row.cny_amount }
        | None -> o)
      others
  in
  let kept = CCList.filter (fun c -> not (merges c && CCList.exists (twins c) others)) cny in
  merged @ kept

let convert_cny row =
  match row.Row.amount with
  | Some _ -> row
  | None -> { row with Row.amount = row.Row.cny_amount }

let prices_of_product = function
  | [] -> []
  | first :: _ as rows ->
      let rows =
        match first.Row.cny_merge with
        | Row.Merge_cny -> merge_cny rows
        | Row.No_cny_merge -> rows
      in
      CCList.map convert_cny rows

let price_of_row
    currency
    {
      Row.price_hash;
      amount;
      product_hash = _;
      cny_amount = _;
      start_usage_amount = _;
      end_usage_amount = _;
      cny_merge = _;
    } =
  Terrat_api_components_infracost_price.make
    ~additional:(Sln_map.String.singleton currency amount)
    { Terrat_api_components_infracost_price.Primary.pricehash = price_hash }

let encode element rows =
  match element with
  | Element.Probe -> probe_response
  | Element.Query
      {
        Filter.currency;
        vendor_name = _;
        service = _;
        product_family = _;
        region = _;
        sku = _;
        attribute_filters = _;
        purchase_option = _;
        unit = _;
        description = _;
        description_regex = _;
        start_usage_amount = _;
        end_usage_amount = _;
        term_length = _;
        term_purchase_option = _;
        term_offering_class = _;
        rate = _;
      } ->
      {
        Terrat_api_components_infracost_graphql_response.data =
          Some
            {
              Terrat_api_components_infracost_graphql_data.products =
                rows
                |> group_by_product
                |> CCList.map (fun rows ->
                    {
                      Terrat_api_components_infracost_product.prices =
                        CCList.map (price_of_row currency) (prices_of_product rows);
                    });
            };
        errors = None;
      }

let indexed_attribute key attribute_filters =
  CCList.find_map
    (function
      | { Attribute_filter.key = key'; match_ = Attribute_filter.Eq value }
        when CCString.equal key key' -> Some value
      | {
          Attribute_filter.key = _;
          match_ =
            ( Attribute_filter.Eq _
            | Attribute_filter.Empty
            | Attribute_filter.Regex _
            | Attribute_filter.Never );
        } -> None)
    attribute_filters

let query db filter =
  let {
    Filter.vendor_name;
    service;
    product_family;
    region;
    sku;
    attribute_filters;
    purchase_option;
    unit;
    description;
    description_regex;
    start_usage_amount;
    end_usage_amount;
    term_length;
    term_purchase_option;
    term_offering_class;
    currency = _;
    rate;
  } =
    filter
  in
  Pgsql_io.Prepared_stmt.fetch
    db
    (Sql.select_prices ())
    ~f:(fun
        product_hash price_hash amount cny_amount start_usage_amount end_usage_amount merges_cny ->
      {
        Row.product_hash;
        price_hash;
        amount;
        cny_amount;
        start_usage_amount;
        end_usage_amount;
        cny_merge = (if merges_cny then Row.Merge_cny else Row.No_cny_merge);
      })
    vendor_name
    service
    product_family
    sku
    region
    (indexed_attribute "instanceType" attribute_filters)
    (indexed_attribute "operatingSystem" attribute_filters)
    (indexed_attribute "capacitystatus" attribute_filters)
    (indexed_attribute "preInstalledSw" attribute_filters)
    (db_attribute_filters_to_yojson (CCList.map Db_attribute_filter.of_filter attribute_filters))
    rate
    Infracost_pricing_currency.cny_to_usd
    purchase_option
    unit
    description
    (CCOption.map (fun { Regex.pattern; case = _ } -> pattern) description_regex)
    (match description_regex with
    | Some { Regex.case = Regex.Insensitive; pattern = _ } -> true
    | Some { Regex.case = Regex.Sensitive; pattern = _ } | None -> false)
    start_usage_amount
    end_usage_amount
    term_length
    term_purchase_option
    term_offering_class

let is_probe = function
  | Element.Probe -> true
  | Element.Query _ -> false

let run_on_conn db elements =
  let open Abbs_fc.Infix_result_monad in
  Abbs_fc.List_result.map
    ~f:(function
      | Element.Probe -> Abb.Future.return (Ok (encode Element.Probe []))
      | Element.Query filter as element -> query db filter >>| fun rows -> encode element rows)
    elements

let run pool elements =
  if CCList.for_all is_probe elements then
    Abb.Future.return (Ok (CCList.map (fun element -> encode element []) elements))
  else Pgsql_pool.with_conn pool ~f:(fun db -> run_on_conn db elements)

module Tests = struct
  module Row = Row

  let regex_of_string = Regex.of_string
  let encode = encode
  let run_on_conn = run_on_conn
end
