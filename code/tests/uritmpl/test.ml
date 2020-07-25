let test_vars =
  let open Uritmpl.Var in
  [
    ("count", A [ "one"; "two"; "three" ]);
    ("dom", A [ "example"; "com" ]);
    ("dub", S "me/too");
    ("hello", S "Hello World!");
    ("half", S "50%");
    ("var", S "value");
    ("who", S "fred");
    ("base", S "http://example.com/home/");
    ("path", S "/foo/bar");
    ("list", A [ "red"; "green"; "blue" ]);
    ("keys", M [ ("semi", ";"); ("dot", "."); ("comma", ",") ]);
    ("v", S "6");
    ("x", S "1024");
    ("y", S "768");
    ("empty", S "");
    ("empty_keys", M []);
  ]

let expand s =
  match Uritmpl.of_string s with
    | Ok tmpl -> Uritmpl.expand tmpl test_vars
    | Error _ -> assert false

let of_string_to_string_matches s =
  match Uritmpl.of_string s with
    | Ok tmpl -> s = Uritmpl.to_string tmpl
    | Error _ -> failwith s

let test_no_variable_expansion =
  Oth.test ~name:"No Variables" (fun _ -> assert (expand "foo" = "foo"))

let test_variable_expansion_3_2_1 =
  Oth.test ~name:"Variable Expansion 3.2.1" (fun _ ->
      assert (expand "{count}" = "one,two,three");
      assert (expand "{count*}" = "one,two,three");
      assert (expand "{/count}" = "/one,two,three");
      assert (expand "{/count*}" = "/one/two/three");
      assert (expand "{;count}" = ";count=one,two,three");
      assert (expand "{;count*}" = ";count=one;count=two;count=three");
      assert (expand "{?count}" = "?count=one,two,three");
      assert (expand "{?count*}" = "?count=one&count=two&count=three");
      assert (expand "{&count*}" = "&count=one&count=two&count=three"))

let test_simple_string_expansion_3_2_2 =
  Oth.test ~name:"Simple String Expansion 3.2.2" (fun _ ->
      assert (expand "{var}" = "value");
      assert (expand "{hello}" = "Hello%20World%21");
      assert (expand "{half}" = "50%25");
      assert (expand "O{empty}X" = "OX");
      assert (expand "O{undef}X" = "OX");
      assert (expand "{x,y}" = "1024,768");
      assert (expand "{x,hello,y}" = "1024,Hello%20World%21,768");
      assert (expand "?{x,empty}" = "?1024,");
      assert (expand "?{x,undef}" = "?1024");
      assert (expand "?{undef,y}" = "?768");
      assert (expand "{var:3}" = "val");
      assert (expand "{var:30}" = "value");
      assert (expand "{list}" = "red,green,blue");
      assert (expand "{list*}" = "red,green,blue");
      assert (expand "{keys}" = "semi,%3B,dot,.,comma,%2C");
      assert (expand "{keys*}" = "semi=%3B,dot=.,comma=%2C"))

let test_reserved_expansion_3_2_3 =
  Oth.test ~name:"Reserved Expansion 3.2.3" (fun _ ->
      assert (expand "{+var}" = "value");
      assert (expand "{+hello}" = "Hello%20World!");
      assert (expand "{+half}" = "50%25");
      assert (expand "{base}index" = "http%3A%2F%2Fexample.com%2Fhome%2Findex");
      assert (expand "{+base}index" = "http://example.com/home/index");
      assert (expand "O{+empty}X" = "OX");
      assert (expand "O{+undef}X" = "OX");
      assert (expand "{+path}/here" = "/foo/bar/here");
      assert (expand "here?ref={+path}" = "here?ref=/foo/bar");
      assert (expand "up{+path}{var}/here" = "up/foo/barvalue/here");
      assert (expand "{+x,hello,y}" = "1024,Hello%20World!,768");
      assert (expand "{+path,x}/here" = "/foo/bar,1024/here");
      assert (expand "{+path:6}/here" = "/foo/b/here");
      assert (expand "{+list}" = "red,green,blue");
      assert (expand "{+list*}" = "red,green,blue");
      assert (expand "{+keys}" = "semi,;,dot,.,comma,,");
      assert (expand "{+keys*}" = "semi=;,dot=.,comma=,"))

let test_fragment_expansion_3_2_4 =
  Oth.test ~name:"Fragment Expansion 3.2.4" (fun _ ->
      assert (expand "{#var}" = "#value");
      assert (expand "{#hello}" = "#Hello%20World!");
      assert (expand "{#half}" = "#50%25");
      assert (expand "foo{#empty}" = "foo#");
      assert (expand "foo{#undef}" = "foo");
      assert (expand "{#x,hello,y}" = "#1024,Hello%20World!,768");
      assert (expand "{#path,x}/here" = "#/foo/bar,1024/here");
      assert (expand "{#path:6}/here" = "#/foo/b/here");
      assert (expand "{#list}" = "#red,green,blue");
      assert (expand "{#list*}" = "#red,green,blue");
      assert (expand "{#keys}" = "#semi,;,dot,.,comma,,");
      assert (expand "{#keys*}" = "#semi=;,dot=.,comma=,"))

let test_label_expansion_with_dot_prefix_3_2_5 =
  Oth.test ~name:"Label Expansion With Dot Prefix 3.2.5" (fun _ ->
      assert (expand "{.who}" = ".fred");
      assert (expand "{.who,who}" = ".fred.fred");
      assert (expand "{.half,who}" = ".50%25.fred");
      assert (expand "www{.dom*}" = "www.example.com");
      assert (expand "X{.var}" = "X.value");
      assert (expand "X{.empty}" = "X.");
      assert (expand "X{.undef}" = "X");
      assert (expand "X{.var:3}" = "X.val");
      assert (expand "X{.list}" = "X.red,green,blue");
      assert (expand "X{.list*}" = "X.red.green.blue");
      assert (expand "X{.keys}" = "X.semi,%3B,dot,.,comma,%2C");
      assert (expand "X{.keys*}" = "X.semi=%3B.dot=..comma=%2C");
      assert (expand "X{.empty_keys}" = "X");
      assert (expand "X{.empty_keys*}" = "X"))

let test_path_segment_expansion_3_2_6 =
  Oth.test ~name:"Path Segment Expansion 3.2.6" (fun _ ->
      assert (expand "{/who}" = "/fred");
      assert (expand "{/who,who}" = "/fred/fred");
      assert (expand "{/half,who}" = "/50%25/fred");
      assert (expand "{/who,dub}" = "/fred/me%2Ftoo");
      assert (expand "{/var}" = "/value");
      assert (expand "{/var,empty}" = "/value/");
      assert (expand "{/var,undef}" = "/value");
      assert (expand "{/var,x}/here" = "/value/1024/here");
      assert (expand "{/var:1,var}" = "/v/value");
      assert (expand "{/list}" = "/red,green,blue");
      assert (expand "{/list*}" = "/red/green/blue");
      assert (expand "{/list*,path:4}" = "/red/green/blue/%2Ffoo");
      assert (expand "{/keys}" = "/semi,%3B,dot,.,comma,%2C");
      assert (expand "{/keys*}" = "/semi=%3B/dot=./comma=%2C"))

let test_path_style_parameter_expansion_3_2_7 =
  Oth.test ~name:"Path-Style Parameter Expansion 3.2.7" (fun _ ->
      assert (expand "{;who}" = ";who=fred");
      assert (expand "{;half}" = ";half=50%25");
      assert (expand "{;empty}" = ";empty");
      assert (expand "{;v,empty,who}" = ";v=6;empty;who=fred");
      assert (expand "{;v,bar,who}" = ";v=6;who=fred");
      assert (expand "{;x,y}" = ";x=1024;y=768");
      assert (expand "{;x,y,empty}" = ";x=1024;y=768;empty");
      assert (expand "{;x,y,undef}" = ";x=1024;y=768");
      assert (expand "{;hello:5}" = ";hello=Hello");
      assert (expand "{;list}" = ";list=red,green,blue");
      assert (expand "{;list*}" = ";list=red;list=green;list=blue");
      assert (expand "{;keys}" = ";keys=semi,%3B,dot,.,comma,%2C");
      assert (expand "{;keys*}" = ";semi=%3B;dot=.;comma=%2C"))

let test_form_style_query_expansion_3_2_8 =
  Oth.test ~name:"Form-Style Query Expansion 3.2.8" (fun _ ->
      assert (expand "{?who}" = "?who=fred");
      assert (expand "{?half}" = "?half=50%25");
      assert (expand "{?x,y}" = "?x=1024&y=768");
      assert (expand "{?x,y,empty}" = "?x=1024&y=768&empty=");
      assert (expand "{?x,y,undef}" = "?x=1024&y=768");
      assert (expand "{?var:3}" = "?var=val");
      assert (expand "{?list}" = "?list=red,green,blue");
      assert (expand "{?list*}" = "?list=red&list=green&list=blue");
      assert (expand "{?keys}" = "?keys=semi,%3B,dot,.,comma,%2C");
      assert (expand "{?keys*}" = "?semi=%3B&dot=.&comma=%2C"))

let test_form_style_query_continuation_3_2_9 =
  Oth.test ~name:"Form-Style Query Continuation 3.2.9" (fun _ ->
      assert (expand "{&who}" = "&who=fred");
      assert (expand "{&half}" = "&half=50%25");
      assert (expand "?fixed=yes{&x}" = "?fixed=yes&x=1024");
      assert (expand "{&x,y,empty}" = "&x=1024&y=768&empty=");
      assert (expand "{&x,y,undef}" = "&x=1024&y=768");
      assert (expand "{&var:3}" = "&var=val");
      assert (expand "{&list}" = "&list=red,green,blue");
      assert (expand "{&list*}" = "&list=red&list=green&list=blue");
      assert (expand "{&keys}" = "&keys=semi,%3B,dot,.,comma,%2C");
      assert (expand "{&keys*}" = "&semi=%3B&dot=.&comma=%2C"))

let test_of_string_to_string =
  Oth.test ~name:"of_string to_string matches" (fun _ ->
      assert (of_string_to_string_matches "foo");
      assert (of_string_to_string_matches "{count}");
      assert (of_string_to_string_matches "{count*}");
      assert (of_string_to_string_matches "{/count}");
      assert (of_string_to_string_matches "{/count*}");
      assert (of_string_to_string_matches "{;count}");
      assert (of_string_to_string_matches "{;count*}");
      assert (of_string_to_string_matches "{?count}");
      assert (of_string_to_string_matches "{?count*}");
      assert (of_string_to_string_matches "{&count*}");
      assert (of_string_to_string_matches "{var}");
      assert (of_string_to_string_matches "{hello}");
      assert (of_string_to_string_matches "{half}");
      assert (of_string_to_string_matches "O{empty}X");
      assert (of_string_to_string_matches "O{undef}X");
      assert (of_string_to_string_matches "{x,y}");
      assert (of_string_to_string_matches "{x,hello,y}");
      assert (of_string_to_string_matches "?{x,empty}");
      assert (of_string_to_string_matches "?{x,undef}");
      assert (of_string_to_string_matches "?{undef,y}");
      assert (of_string_to_string_matches "{var:3}");
      assert (of_string_to_string_matches "{var:30}");
      assert (of_string_to_string_matches "{list}");
      assert (of_string_to_string_matches "{list*}");
      assert (of_string_to_string_matches "{keys}");
      assert (of_string_to_string_matches "{keys*}");
      assert (of_string_to_string_matches "{+var}");
      assert (of_string_to_string_matches "{+hello}");
      assert (of_string_to_string_matches "{+half}");
      assert (of_string_to_string_matches "{base}index");
      assert (of_string_to_string_matches "{+base}index");
      assert (of_string_to_string_matches "O{+empty}X");
      assert (of_string_to_string_matches "O{+undef}X");
      assert (of_string_to_string_matches "{+path}/here");
      assert (of_string_to_string_matches "here?ref={+path}");
      assert (of_string_to_string_matches "up{+path}{var}/here");
      assert (of_string_to_string_matches "{+x,hello,y}");
      assert (of_string_to_string_matches "{+path,x}/here");
      assert (of_string_to_string_matches "{+path:6}/here");
      assert (of_string_to_string_matches "{+list}");
      assert (of_string_to_string_matches "{+list*}");
      assert (of_string_to_string_matches "{+keys}");
      assert (of_string_to_string_matches "{+keys*}");
      assert (of_string_to_string_matches "{#var}");
      assert (of_string_to_string_matches "{#hello}");
      assert (of_string_to_string_matches "{#half}");
      assert (of_string_to_string_matches "foo{#empty}");
      assert (of_string_to_string_matches "foo{#undef}");
      assert (of_string_to_string_matches "{#x,hello,y}");
      assert (of_string_to_string_matches "{#path,x}/here");
      assert (of_string_to_string_matches "{#path:6}/here");
      assert (of_string_to_string_matches "{#list}");
      assert (of_string_to_string_matches "{#list*}");
      assert (of_string_to_string_matches "{#keys}");
      assert (of_string_to_string_matches "{#keys*}");
      assert (of_string_to_string_matches "{.who}");
      assert (of_string_to_string_matches "{.who,who}");
      assert (of_string_to_string_matches "{.half,who}");
      assert (of_string_to_string_matches "www{.dom*}");
      assert (of_string_to_string_matches "X{.var}");
      assert (of_string_to_string_matches "X{.empty}");
      assert (of_string_to_string_matches "X{.undef}");
      assert (of_string_to_string_matches "X{.var:3}");
      assert (of_string_to_string_matches "X{.list}");
      assert (of_string_to_string_matches "X{.list*}");
      assert (of_string_to_string_matches "X{.keys}");
      assert (of_string_to_string_matches "X{.keys*}");
      assert (of_string_to_string_matches "X{.empty_keys}");
      assert (of_string_to_string_matches "X{.empty_keys*}");
      assert (of_string_to_string_matches "{/who}");
      assert (of_string_to_string_matches "{/who,who}");
      assert (of_string_to_string_matches "{/half,who}");
      assert (of_string_to_string_matches "{/who,dub}");
      assert (of_string_to_string_matches "{/var}");
      assert (of_string_to_string_matches "{/var,empty}");
      assert (of_string_to_string_matches "{/var,undef}");
      assert (of_string_to_string_matches "{/var,x}/here");
      assert (of_string_to_string_matches "{/var:1,var}");
      assert (of_string_to_string_matches "{/list}");
      assert (of_string_to_string_matches "{/list*}");
      assert (of_string_to_string_matches "{/list*,path:4}");
      assert (of_string_to_string_matches "{/keys}");
      assert (of_string_to_string_matches "{/keys*}");
      assert (of_string_to_string_matches "{;who}");
      assert (of_string_to_string_matches "{;half}");
      assert (of_string_to_string_matches "{;empty}");
      assert (of_string_to_string_matches "{;v,empty,who}");
      assert (of_string_to_string_matches "{;v,bar,who}");
      assert (of_string_to_string_matches "{;x,y}");
      assert (of_string_to_string_matches "{;x,y,empty}");
      assert (of_string_to_string_matches "{;x,y,undef}");
      assert (of_string_to_string_matches "{;hello:5}");
      assert (of_string_to_string_matches "{;list}");
      assert (of_string_to_string_matches "{;list*}");
      assert (of_string_to_string_matches "{;keys}");
      assert (of_string_to_string_matches "{;keys*}");
      assert (of_string_to_string_matches "{?who}");
      assert (of_string_to_string_matches "{?half}");
      assert (of_string_to_string_matches "{?x,y}");
      assert (of_string_to_string_matches "{?x,y,empty}");
      assert (of_string_to_string_matches "{?x,y,undef}");
      assert (of_string_to_string_matches "{?var:3}");
      assert (of_string_to_string_matches "{?list}");
      assert (of_string_to_string_matches "{?list*}");
      assert (of_string_to_string_matches "{?keys}");
      assert (of_string_to_string_matches "{?keys*}");
      assert (of_string_to_string_matches "{&who}");
      assert (of_string_to_string_matches "{&half}");
      assert (of_string_to_string_matches "?fixed=yes{&x}");
      assert (of_string_to_string_matches "{&x,y,empty}");
      assert (of_string_to_string_matches "{&x,y,undef}");
      assert (of_string_to_string_matches "{&var:3}");
      assert (of_string_to_string_matches "{&list}");
      assert (of_string_to_string_matches "{&list*}");
      assert (of_string_to_string_matches "{&keys}");
      assert (of_string_to_string_matches "{&keys*}"))

let test =
  Oth.parallel
    [
      test_no_variable_expansion;
      test_variable_expansion_3_2_1;
      test_simple_string_expansion_3_2_2;
      test_reserved_expansion_3_2_3;
      test_fragment_expansion_3_2_4;
      test_label_expansion_with_dot_prefix_3_2_5;
      test_path_segment_expansion_3_2_6;
      test_path_style_parameter_expansion_3_2_7;
      test_form_style_query_expansion_3_2_8;
      test_form_style_query_continuation_3_2_9;
      test_of_string_to_string;
    ]

let () =
  Random.self_init ();
  Oth.run test
