let rec map_in_expr f expr =
  match f expr with
  | Some replaced -> replaced
  | None -> recurse_map_in_expr f expr

and recurse_map_in_expr f expr =
  let module E = Hcl_parser_value.Expr in
  match expr with
  | E.Id _ | E.String _ | E.Int _ | E.Float _ | E.Bool _ | E.Null | E.Splat
  | E.Heredoc (_, _)
  | E.Heredoc' (_, _) -> expr
  | E.Template parts -> E.Template (CCList.map (map_in_template_part f) parts)
  | E.Template_heredoc (marker, parts) ->
      E.Template_heredoc (marker, CCList.map (map_in_template_part f) parts)
  | E.Tuple items -> E.Tuple (CCList.map (map_in_expr f) items)
  | E.Object pairs ->
      E.Object (CCList.map (fun (k, v) -> (map_in_obj_key f k, map_in_expr f v)) pairs)
  | E.Fun_call (name, args) -> E.Fun_call (name, CCList.map (map_in_expr f) args)
  | E.For_tuple { identifiers; input; output; cond } ->
      E.For_tuple
        {
          identifiers;
          input = map_in_expr f input;
          output = map_in_expr f output;
          cond = CCOption.map (map_in_expr f) cond;
        }
  | E.For_object { identifiers; input; key_output; value_output; cond } ->
      E.For_object
        {
          identifiers;
          input = map_in_expr f input;
          key_output = map_in_expr f key_output;
          value_output = map_in_expr f value_output;
          cond = CCOption.map (map_in_expr f) cond;
        }
  | E.Cond { if_; then_; else_ } ->
      E.Cond { if_ = map_in_expr f if_; then_ = map_in_expr f then_; else_ = map_in_expr f else_ }
  | E.Idx (e, idx) -> E.Idx (map_in_expr f e, map_in_expr f idx)
  | E.Attr (e, attr) -> E.Attr (map_in_expr f e, attr)
  | E.Not e -> E.Not (map_in_expr f e)
  | E.Minus e -> E.Minus (map_in_expr f e)
  | E.Add (a, b) -> E.Add (map_in_expr f a, map_in_expr f b)
  | E.Subtract (a, b) -> E.Subtract (map_in_expr f a, map_in_expr f b)
  | E.Mult (a, b) -> E.Mult (map_in_expr f a, map_in_expr f b)
  | E.Div (a, b) -> E.Div (map_in_expr f a, map_in_expr f b)
  | E.Log_and (a, b) -> E.Log_and (map_in_expr f a, map_in_expr f b)
  | E.Log_or (a, b) -> E.Log_or (map_in_expr f a, map_in_expr f b)
  | E.Equal (a, b) -> E.Equal (map_in_expr f a, map_in_expr f b)
  | E.Not_equal (a, b) -> E.Not_equal (map_in_expr f a, map_in_expr f b)
  | E.Gt (a, b) -> E.Gt (map_in_expr f a, map_in_expr f b)
  | E.Lt (a, b) -> E.Lt (map_in_expr f a, map_in_expr f b)
  | E.Gte (a, b) -> E.Gte (map_in_expr f a, map_in_expr f b)
  | E.Lte (a, b) -> E.Lte (map_in_expr f a, map_in_expr f b)
  | E.Mod (a, b) -> E.Mod (map_in_expr f a, map_in_expr f b)
  | E.Ellipsis e -> E.Ellipsis (map_in_expr f e)

and map_in_obj_key f k =
  let module K = Hcl_parser_value.Obj_key in
  match k with
  | K.Bare _ | K.Quoted _ -> k
  | K.Template parts -> K.Template (CCList.map (map_in_template_part f) parts)
  | K.Computed e -> K.Computed (map_in_expr f e)
  | K.Expr e -> K.Expr (map_in_expr f e)

and map_in_template_part f part =
  let module T = Hcl_parser_value.Template_part in
  match part with
  | T.Literal _ -> part
  | T.Interpolation { expr; strip_before; strip_after } ->
      T.Interpolation { expr = map_in_expr f expr; strip_before; strip_after }
  | T.If_directive { cond; then_; else_; strip_before; strip_after } ->
      T.If_directive
        {
          cond = map_in_expr f cond;
          then_ = CCList.map (map_in_template_part f) then_;
          else_ = CCOption.map (CCList.map (map_in_template_part f)) else_;
          strip_before;
          strip_after;
        }
  | T.For_directive { vars; input; body; strip_before; strip_after } ->
      T.For_directive
        {
          vars;
          input = map_in_expr f input;
          body = CCList.map (map_in_template_part f) body;
          strip_before;
          strip_after;
        }

let fold_in_expr f init expr =
  let module E = Hcl_parser_value.Expr in
  let module K = Hcl_parser_value.Obj_key in
  let module T = Hcl_parser_value.Template_part in
  let rec go acc e =
    match f acc e with
    | `Stop a -> a
    | `Continue acc -> (
        match e with
        | E.Id _
        | E.String _
        | E.Int _
        | E.Float _
        | E.Bool _
        | E.Null
        | E.Splat
        | E.Heredoc _
        | E.Heredoc' _ -> acc
        | E.Template parts | E.Template_heredoc (_, parts) -> CCList.fold_left go_template acc parts
        | E.Tuple items -> CCList.fold_left go acc items
        | E.Object pairs ->
            CCList.fold_left
              (fun acc (k, v) ->
                let acc = go_obj_key acc k in
                go acc v)
              acc
              pairs
        | E.Fun_call (_, args) -> CCList.fold_left go acc args
        | E.For_tuple { input; output; cond; _ } ->
            let acc = go acc input in
            let acc = go acc output in
            CCOption.map_or ~default:acc (go acc) cond
        | E.For_object { input; key_output; value_output; cond; _ } ->
            let acc = go acc input in
            let acc = go acc key_output in
            let acc = go acc value_output in
            CCOption.map_or ~default:acc (go acc) cond
        | E.Cond { if_; then_; else_ } ->
            let acc = go acc if_ in
            let acc = go acc then_ in
            go acc else_
        | E.Idx (a, b)
        | E.Add (a, b)
        | E.Subtract (a, b)
        | E.Mult (a, b)
        | E.Div (a, b)
        | E.Log_and (a, b)
        | E.Log_or (a, b)
        | E.Equal (a, b)
        | E.Not_equal (a, b)
        | E.Gt (a, b)
        | E.Lt (a, b)
        | E.Gte (a, b)
        | E.Lte (a, b)
        | E.Mod (a, b) ->
            let acc = go acc a in
            go acc b
        | E.Attr (e, _) | E.Not e | E.Minus e | E.Ellipsis e -> go acc e)
  and go_obj_key acc k =
    match k with
    | K.Bare _ | K.Quoted _ -> acc
    | K.Template parts -> CCList.fold_left go_template acc parts
    | K.Computed e | K.Expr e -> go acc e
  and go_template acc part =
    match part with
    | T.Literal _ -> acc
    | T.Interpolation { expr; _ } -> go acc expr
    | T.If_directive { cond; then_; else_; _ } ->
        let acc = go acc cond in
        let acc = CCList.fold_left go_template acc then_ in
        CCOption.map_or ~default:acc (CCList.fold_left go_template acc) else_
    | T.For_directive { input; body; _ } ->
        let acc = go acc input in
        CCList.fold_left go_template acc body
  in
  go init expr

let map_in_body f ast =
  let rec map_item item =
    match item with
    | Hcl_parser_value.Block { type_; labels; body } ->
        Hcl_parser_value.Block { type_; labels; body = CCList.map map_item body }
    | Hcl_parser_value.Attribute (name, expr) ->
        Hcl_parser_value.Attribute (name, map_in_expr f expr)
  in
  CCList.map map_item ast
