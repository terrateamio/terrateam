open Crowbar

let () =
  add_test ~name:"create" [bytes] (fun a ->
    (* Parse \n as this is a known deviation of behaviour *)
    let a = Str.(global_replace (regexp_string "\n") a "") in
    let x = try Uri.(of_string a |> to_string) with _ -> "" in
    let y = try Uri_legacy.(of_string a |> to_string) with _ -> "" in
    check_eq ~pp:pp_string x y
  );
  add_test ~name:"query" [bytes] (fun a ->
    (* Parse \n as this is a known deviation of behaviour *)
    let a = Str.(global_replace (regexp_string "\n") a "") in
    let x = try Uri.(of_string a |> query) with _ -> [] in
    let y = try Uri_legacy.(of_string a |> query) with _ -> [] in
    check_eq x y
  );
  add_test ~name:"scheme" [bytes] (fun a ->
    (* Parse \n as this is a known deviation of behaviour *)
    let a = Str.(global_replace (regexp_string "\n") a "") in
    let x = try Uri.(of_string a |> scheme) with _ -> None in
    let y = try Uri_legacy.(of_string a |> scheme) with _ -> None in
    check_eq x y
  );
  add_test ~name:"host" [bytes] (fun a ->
    (* Parse \n as this is a known deviation of behaviour *)
    let a = Str.(global_replace (regexp_string "\n") a "") in
    let x = try Uri.(of_string a |> host) with _ -> None in
    let y = try Uri_legacy.(of_string a |> host) with _ -> None in
    check_eq x y
  );
  add_test ~name:"userinfo" [bytes] (fun a ->
    (* Parse \n as this is a known deviation of behaviour *)
    let a = Str.(global_replace (regexp_string "\n") a "") in
    let x = try Uri.(of_string a |> userinfo) with _ -> None in
    let y = try Uri_legacy.(of_string a |> userinfo) with _ -> None in
    check_eq x y
  );
  add_test ~name:"port" [bytes] (fun a ->
    (* Parse \n as this is a known deviation of behaviour *)
    let a = Str.(global_replace (regexp_string "\n") a "") in
    let x = try Uri.(of_string a |> port) with _ -> None in
    let y = try Uri_legacy.(of_string a |> port) with _ -> None in
    check_eq x y
  );
  
