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
  | Error _ -> Oth.Assert.false_ "test: unexpected value"

let of_string_to_string_matches s =
  match Uritmpl.of_string s with
  | Ok tmpl -> s = Uritmpl.to_string tmpl
  | Error _ -> failwith s

let test_no_variable_expansion =
  Oth.test ~name:"No Variables" (fun _ ->
      Oth.Assert.Eq.string ~expected:"foo" ~actual:(expand "foo"))

let test_variable_expansion_3_2_1 =
  Oth.test ~name:"Variable Expansion 3.2.1" (fun _ ->
      Oth.Assert.Eq.string ~expected:"one,two,three" ~actual:(expand "{count}");
      Oth.Assert.Eq.string ~expected:"one,two,three" ~actual:(expand "{count*}");
      Oth.Assert.Eq.string ~expected:"/one,two,three" ~actual:(expand "{/count}");
      Oth.Assert.Eq.string ~expected:"/one/two/three" ~actual:(expand "{/count*}");
      Oth.Assert.Eq.string ~expected:";count=one,two,three" ~actual:(expand "{;count}");
      Oth.Assert.Eq.string ~expected:";count=one;count=two;count=three" ~actual:(expand "{;count*}");
      Oth.Assert.Eq.string ~expected:"?count=one,two,three" ~actual:(expand "{?count}");
      Oth.Assert.Eq.string ~expected:"?count=one&count=two&count=three" ~actual:(expand "{?count*}");
      Oth.Assert.Eq.string ~expected:"&count=one&count=two&count=three" ~actual:(expand "{&count*}"))

let test_simple_string_expansion_3_2_2 =
  Oth.test ~name:"Simple String Expansion 3.2.2" (fun _ ->
      Oth.Assert.Eq.string ~expected:"value" ~actual:(expand "{var}");
      Oth.Assert.Eq.string ~expected:"Hello%20World%21" ~actual:(expand "{hello}");
      Oth.Assert.Eq.string ~expected:"50%25" ~actual:(expand "{half}");
      Oth.Assert.Eq.string ~expected:"OX" ~actual:(expand "O{empty}X");
      Oth.Assert.Eq.string ~expected:"OX" ~actual:(expand "O{undef}X");
      Oth.Assert.Eq.string ~expected:"1024,768" ~actual:(expand "{x,y}");
      Oth.Assert.Eq.string ~expected:"1024,Hello%20World%21,768" ~actual:(expand "{x,hello,y}");
      Oth.Assert.Eq.string ~expected:"?1024," ~actual:(expand "?{x,empty}");
      Oth.Assert.Eq.string ~expected:"?1024" ~actual:(expand "?{x,undef}");
      Oth.Assert.Eq.string ~expected:"?768" ~actual:(expand "?{undef,y}");
      Oth.Assert.Eq.string ~expected:"val" ~actual:(expand "{var:3}");
      Oth.Assert.Eq.string ~expected:"value" ~actual:(expand "{var:30}");
      Oth.Assert.Eq.string ~expected:"red,green,blue" ~actual:(expand "{list}");
      Oth.Assert.Eq.string ~expected:"red,green,blue" ~actual:(expand "{list*}");
      Oth.Assert.Eq.string ~expected:"semi,%3B,dot,.,comma,%2C" ~actual:(expand "{keys}");
      Oth.Assert.Eq.string ~expected:"semi=%3B,dot=.,comma=%2C" ~actual:(expand "{keys*}"))

let test_reserved_expansion_3_2_3 =
  Oth.test ~name:"Reserved Expansion 3.2.3" (fun _ ->
      Oth.Assert.Eq.string ~expected:"value" ~actual:(expand "{+var}");
      Oth.Assert.Eq.string ~expected:"Hello%20World!" ~actual:(expand "{+hello}");
      Oth.Assert.Eq.string ~expected:"50%25" ~actual:(expand "{+half}");
      Oth.Assert.Eq.string
        ~expected:"http%3A%2F%2Fexample.com%2Fhome%2Findex"
        ~actual:(expand "{base}index");
      Oth.Assert.Eq.string ~expected:"http://example.com/home/index" ~actual:(expand "{+base}index");
      Oth.Assert.Eq.string ~expected:"OX" ~actual:(expand "O{+empty}X");
      Oth.Assert.Eq.string ~expected:"OX" ~actual:(expand "O{+undef}X");
      Oth.Assert.Eq.string ~expected:"/foo/bar/here" ~actual:(expand "{+path}/here");
      Oth.Assert.Eq.string ~expected:"here?ref=/foo/bar" ~actual:(expand "here?ref={+path}");
      Oth.Assert.Eq.string ~expected:"up/foo/barvalue/here" ~actual:(expand "up{+path}{var}/here");
      Oth.Assert.Eq.string ~expected:"1024,Hello%20World!,768" ~actual:(expand "{+x,hello,y}");
      Oth.Assert.Eq.string ~expected:"/foo/bar,1024/here" ~actual:(expand "{+path,x}/here");
      Oth.Assert.Eq.string ~expected:"/foo/b/here" ~actual:(expand "{+path:6}/here");
      Oth.Assert.Eq.string ~expected:"red,green,blue" ~actual:(expand "{+list}");
      Oth.Assert.Eq.string ~expected:"red,green,blue" ~actual:(expand "{+list*}");
      Oth.Assert.Eq.string ~expected:"semi,;,dot,.,comma,," ~actual:(expand "{+keys}");
      Oth.Assert.Eq.string ~expected:"semi=;,dot=.,comma=," ~actual:(expand "{+keys*}"))

let test_fragment_expansion_3_2_4 =
  Oth.test ~name:"Fragment Expansion 3.2.4" (fun _ ->
      Oth.Assert.Eq.string ~expected:"#value" ~actual:(expand "{#var}");
      Oth.Assert.Eq.string ~expected:"#Hello%20World!" ~actual:(expand "{#hello}");
      Oth.Assert.Eq.string ~expected:"#50%25" ~actual:(expand "{#half}");
      Oth.Assert.Eq.string ~expected:"foo#" ~actual:(expand "foo{#empty}");
      Oth.Assert.Eq.string ~expected:"foo" ~actual:(expand "foo{#undef}");
      Oth.Assert.Eq.string ~expected:"#1024,Hello%20World!,768" ~actual:(expand "{#x,hello,y}");
      Oth.Assert.Eq.string ~expected:"#/foo/bar,1024/here" ~actual:(expand "{#path,x}/here");
      Oth.Assert.Eq.string ~expected:"#/foo/b/here" ~actual:(expand "{#path:6}/here");
      Oth.Assert.Eq.string ~expected:"#red,green,blue" ~actual:(expand "{#list}");
      Oth.Assert.Eq.string ~expected:"#red,green,blue" ~actual:(expand "{#list*}");
      Oth.Assert.Eq.string ~expected:"#semi,;,dot,.,comma,," ~actual:(expand "{#keys}");
      Oth.Assert.Eq.string ~expected:"#semi=;,dot=.,comma=," ~actual:(expand "{#keys*}"))

let test_label_expansion_with_dot_prefix_3_2_5 =
  Oth.test ~name:"Label Expansion With Dot Prefix 3.2.5" (fun _ ->
      Oth.Assert.Eq.string ~expected:".fred" ~actual:(expand "{.who}");
      Oth.Assert.Eq.string ~expected:".fred.fred" ~actual:(expand "{.who,who}");
      Oth.Assert.Eq.string ~expected:".50%25.fred" ~actual:(expand "{.half,who}");
      Oth.Assert.Eq.string ~expected:"www.example.com" ~actual:(expand "www{.dom*}");
      Oth.Assert.Eq.string ~expected:"X.value" ~actual:(expand "X{.var}");
      Oth.Assert.Eq.string ~expected:"X." ~actual:(expand "X{.empty}");
      Oth.Assert.Eq.string ~expected:"X" ~actual:(expand "X{.undef}");
      Oth.Assert.Eq.string ~expected:"X.val" ~actual:(expand "X{.var:3}");
      Oth.Assert.Eq.string ~expected:"X.red,green,blue" ~actual:(expand "X{.list}");
      Oth.Assert.Eq.string ~expected:"X.red.green.blue" ~actual:(expand "X{.list*}");
      Oth.Assert.Eq.string ~expected:"X.semi,%3B,dot,.,comma,%2C" ~actual:(expand "X{.keys}");
      Oth.Assert.Eq.string ~expected:"X.semi=%3B.dot=..comma=%2C" ~actual:(expand "X{.keys*}");
      Oth.Assert.Eq.string ~expected:"X" ~actual:(expand "X{.empty_keys}");
      Oth.Assert.Eq.string ~expected:"X" ~actual:(expand "X{.empty_keys*}"))

let test_path_segment_expansion_3_2_6 =
  Oth.test ~name:"Path Segment Expansion 3.2.6" (fun _ ->
      Oth.Assert.Eq.string ~expected:"/fred" ~actual:(expand "{/who}");
      Oth.Assert.Eq.string ~expected:"/fred/fred" ~actual:(expand "{/who,who}");
      Oth.Assert.Eq.string ~expected:"/50%25/fred" ~actual:(expand "{/half,who}");
      Oth.Assert.Eq.string ~expected:"/fred/me%2Ftoo" ~actual:(expand "{/who,dub}");
      Oth.Assert.Eq.string ~expected:"/value" ~actual:(expand "{/var}");
      Oth.Assert.Eq.string ~expected:"/value/" ~actual:(expand "{/var,empty}");
      Oth.Assert.Eq.string ~expected:"/value" ~actual:(expand "{/var,undef}");
      Oth.Assert.Eq.string ~expected:"/value/1024/here" ~actual:(expand "{/var,x}/here");
      Oth.Assert.Eq.string ~expected:"/v/value" ~actual:(expand "{/var:1,var}");
      Oth.Assert.Eq.string ~expected:"/red,green,blue" ~actual:(expand "{/list}");
      Oth.Assert.Eq.string ~expected:"/red/green/blue" ~actual:(expand "{/list*}");
      Oth.Assert.Eq.string ~expected:"/red/green/blue/%2Ffoo" ~actual:(expand "{/list*,path:4}");
      Oth.Assert.Eq.string ~expected:"/semi,%3B,dot,.,comma,%2C" ~actual:(expand "{/keys}");
      Oth.Assert.Eq.string ~expected:"/semi=%3B/dot=./comma=%2C" ~actual:(expand "{/keys*}"))

let test_path_style_parameter_expansion_3_2_7 =
  Oth.test ~name:"Path-Style Parameter Expansion 3.2.7" (fun _ ->
      Oth.Assert.Eq.string ~expected:";who=fred" ~actual:(expand "{;who}");
      Oth.Assert.Eq.string ~expected:";half=50%25" ~actual:(expand "{;half}");
      Oth.Assert.Eq.string ~expected:";empty" ~actual:(expand "{;empty}");
      Oth.Assert.Eq.string ~expected:";v=6;empty;who=fred" ~actual:(expand "{;v,empty,who}");
      Oth.Assert.Eq.string ~expected:";v=6;who=fred" ~actual:(expand "{;v,bar,who}");
      Oth.Assert.Eq.string ~expected:";x=1024;y=768" ~actual:(expand "{;x,y}");
      Oth.Assert.Eq.string ~expected:";x=1024;y=768;empty" ~actual:(expand "{;x,y,empty}");
      Oth.Assert.Eq.string ~expected:";x=1024;y=768" ~actual:(expand "{;x,y,undef}");
      Oth.Assert.Eq.string ~expected:";hello=Hello" ~actual:(expand "{;hello:5}");
      Oth.Assert.Eq.string ~expected:";list=red,green,blue" ~actual:(expand "{;list}");
      Oth.Assert.Eq.string ~expected:";list=red;list=green;list=blue" ~actual:(expand "{;list*}");
      Oth.Assert.Eq.string ~expected:";keys=semi,%3B,dot,.,comma,%2C" ~actual:(expand "{;keys}");
      Oth.Assert.Eq.string ~expected:";semi=%3B;dot=.;comma=%2C" ~actual:(expand "{;keys*}"))

let test_form_style_query_expansion_3_2_8 =
  Oth.test ~name:"Form-Style Query Expansion 3.2.8" (fun _ ->
      Oth.Assert.Eq.string ~expected:"?who=fred" ~actual:(expand "{?who}");
      Oth.Assert.Eq.string ~expected:"?half=50%25" ~actual:(expand "{?half}");
      Oth.Assert.Eq.string ~expected:"?x=1024&y=768" ~actual:(expand "{?x,y}");
      Oth.Assert.Eq.string ~expected:"?x=1024&y=768&empty=" ~actual:(expand "{?x,y,empty}");
      Oth.Assert.Eq.string ~expected:"?x=1024&y=768" ~actual:(expand "{?x,y,undef}");
      Oth.Assert.Eq.string ~expected:"?var=val" ~actual:(expand "{?var:3}");
      Oth.Assert.Eq.string ~expected:"?list=red,green,blue" ~actual:(expand "{?list}");
      Oth.Assert.Eq.string ~expected:"?list=red&list=green&list=blue" ~actual:(expand "{?list*}");
      Oth.Assert.Eq.string ~expected:"?keys=semi,%3B,dot,.,comma,%2C" ~actual:(expand "{?keys}");
      Oth.Assert.Eq.string ~expected:"?semi=%3B&dot=.&comma=%2C" ~actual:(expand "{?keys*}"))

let test_form_style_query_continuation_3_2_9 =
  Oth.test ~name:"Form-Style Query Continuation 3.2.9" (fun _ ->
      Oth.Assert.Eq.string ~expected:"&who=fred" ~actual:(expand "{&who}");
      Oth.Assert.Eq.string ~expected:"&half=50%25" ~actual:(expand "{&half}");
      Oth.Assert.Eq.string ~expected:"?fixed=yes&x=1024" ~actual:(expand "?fixed=yes{&x}");
      Oth.Assert.Eq.string ~expected:"&x=1024&y=768&empty=" ~actual:(expand "{&x,y,empty}");
      Oth.Assert.Eq.string ~expected:"&x=1024&y=768" ~actual:(expand "{&x,y,undef}");
      Oth.Assert.Eq.string ~expected:"&var=val" ~actual:(expand "{&var:3}");
      Oth.Assert.Eq.string ~expected:"&list=red,green,blue" ~actual:(expand "{&list}");
      Oth.Assert.Eq.string ~expected:"&list=red&list=green&list=blue" ~actual:(expand "{&list*}");
      Oth.Assert.Eq.string ~expected:"&keys=semi,%3B,dot,.,comma,%2C" ~actual:(expand "{&keys}");
      Oth.Assert.Eq.string ~expected:"&semi=%3B&dot=.&comma=%2C" ~actual:(expand "{&keys*}"))

let test_of_string_to_string =
  Oth.test ~name:"of_string to_string matches" (fun _ ->
      Oth.Assert.true_ "of_string_to_string_matches \"foo\"" (of_string_to_string_matches "foo");
      Oth.Assert.true_
        "of_string_to_string_matches \"{count}\""
        (of_string_to_string_matches "{count}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{count*}\""
        (of_string_to_string_matches "{count*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/count}\""
        (of_string_to_string_matches "{/count}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/count*}\""
        (of_string_to_string_matches "{/count*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;count}\""
        (of_string_to_string_matches "{;count}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;count*}\""
        (of_string_to_string_matches "{;count*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?count}\""
        (of_string_to_string_matches "{?count}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?count*}\""
        (of_string_to_string_matches "{?count*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&count*}\""
        (of_string_to_string_matches "{&count*}");
      Oth.Assert.true_ "of_string_to_string_matches \"{var}\"" (of_string_to_string_matches "{var}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{hello}\""
        (of_string_to_string_matches "{hello}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{half}\""
        (of_string_to_string_matches "{half}");
      Oth.Assert.true_
        "of_string_to_string_matches \"O{empty}X\""
        (of_string_to_string_matches "O{empty}X");
      Oth.Assert.true_
        "of_string_to_string_matches \"O{undef}X\""
        (of_string_to_string_matches "O{undef}X");
      Oth.Assert.true_ "of_string_to_string_matches \"{x,y}\"" (of_string_to_string_matches "{x,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{x,hello,y}\""
        (of_string_to_string_matches "{x,hello,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"?{x,empty}\""
        (of_string_to_string_matches "?{x,empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"?{x,undef}\""
        (of_string_to_string_matches "?{x,undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"?{undef,y}\""
        (of_string_to_string_matches "?{undef,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{var:3}\""
        (of_string_to_string_matches "{var:3}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{var:30}\""
        (of_string_to_string_matches "{var:30}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{list}\""
        (of_string_to_string_matches "{list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{list*}\""
        (of_string_to_string_matches "{list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{keys}\""
        (of_string_to_string_matches "{keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{keys*}\""
        (of_string_to_string_matches "{keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+var}\""
        (of_string_to_string_matches "{+var}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+hello}\""
        (of_string_to_string_matches "{+hello}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+half}\""
        (of_string_to_string_matches "{+half}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{base}index\""
        (of_string_to_string_matches "{base}index");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+base}index\""
        (of_string_to_string_matches "{+base}index");
      Oth.Assert.true_
        "of_string_to_string_matches \"O{+empty}X\""
        (of_string_to_string_matches "O{+empty}X");
      Oth.Assert.true_
        "of_string_to_string_matches \"O{+undef}X\""
        (of_string_to_string_matches "O{+undef}X");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+path}/here\""
        (of_string_to_string_matches "{+path}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"here?ref={+path}\""
        (of_string_to_string_matches "here?ref={+path}");
      Oth.Assert.true_
        "of_string_to_string_matches \"up{+path}{var}/here\""
        (of_string_to_string_matches "up{+path}{var}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+x,hello,y}\""
        (of_string_to_string_matches "{+x,hello,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+path,x}/here\""
        (of_string_to_string_matches "{+path,x}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+path:6}/here\""
        (of_string_to_string_matches "{+path:6}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+list}\""
        (of_string_to_string_matches "{+list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+list*}\""
        (of_string_to_string_matches "{+list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+keys}\""
        (of_string_to_string_matches "{+keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{+keys*}\""
        (of_string_to_string_matches "{+keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#var}\""
        (of_string_to_string_matches "{#var}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#hello}\""
        (of_string_to_string_matches "{#hello}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#half}\""
        (of_string_to_string_matches "{#half}");
      Oth.Assert.true_
        "of_string_to_string_matches \"foo{#empty}\""
        (of_string_to_string_matches "foo{#empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"foo{#undef}\""
        (of_string_to_string_matches "foo{#undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#x,hello,y}\""
        (of_string_to_string_matches "{#x,hello,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#path,x}/here\""
        (of_string_to_string_matches "{#path,x}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#path:6}/here\""
        (of_string_to_string_matches "{#path:6}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#list}\""
        (of_string_to_string_matches "{#list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#list*}\""
        (of_string_to_string_matches "{#list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#keys}\""
        (of_string_to_string_matches "{#keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{#keys*}\""
        (of_string_to_string_matches "{#keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{.who}\""
        (of_string_to_string_matches "{.who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{.who,who}\""
        (of_string_to_string_matches "{.who,who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{.half,who}\""
        (of_string_to_string_matches "{.half,who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"www{.dom*}\""
        (of_string_to_string_matches "www{.dom*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.var}\""
        (of_string_to_string_matches "X{.var}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.empty}\""
        (of_string_to_string_matches "X{.empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.undef}\""
        (of_string_to_string_matches "X{.undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.var:3}\""
        (of_string_to_string_matches "X{.var:3}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.list}\""
        (of_string_to_string_matches "X{.list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.list*}\""
        (of_string_to_string_matches "X{.list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.keys}\""
        (of_string_to_string_matches "X{.keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.keys*}\""
        (of_string_to_string_matches "X{.keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.empty_keys}\""
        (of_string_to_string_matches "X{.empty_keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"X{.empty_keys*}\""
        (of_string_to_string_matches "X{.empty_keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/who}\""
        (of_string_to_string_matches "{/who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/who,who}\""
        (of_string_to_string_matches "{/who,who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/half,who}\""
        (of_string_to_string_matches "{/half,who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/who,dub}\""
        (of_string_to_string_matches "{/who,dub}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/var}\""
        (of_string_to_string_matches "{/var}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/var,empty}\""
        (of_string_to_string_matches "{/var,empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/var,undef}\""
        (of_string_to_string_matches "{/var,undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/var,x}/here\""
        (of_string_to_string_matches "{/var,x}/here");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/var:1,var}\""
        (of_string_to_string_matches "{/var:1,var}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/list}\""
        (of_string_to_string_matches "{/list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/list*}\""
        (of_string_to_string_matches "{/list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/list*,path:4}\""
        (of_string_to_string_matches "{/list*,path:4}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/keys}\""
        (of_string_to_string_matches "{/keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{/keys*}\""
        (of_string_to_string_matches "{/keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;who}\""
        (of_string_to_string_matches "{;who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;half}\""
        (of_string_to_string_matches "{;half}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;empty}\""
        (of_string_to_string_matches "{;empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;v,empty,who}\""
        (of_string_to_string_matches "{;v,empty,who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;v,bar,who}\""
        (of_string_to_string_matches "{;v,bar,who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;x,y}\""
        (of_string_to_string_matches "{;x,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;x,y,empty}\""
        (of_string_to_string_matches "{;x,y,empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;x,y,undef}\""
        (of_string_to_string_matches "{;x,y,undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;hello:5}\""
        (of_string_to_string_matches "{;hello:5}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;list}\""
        (of_string_to_string_matches "{;list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;list*}\""
        (of_string_to_string_matches "{;list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;keys}\""
        (of_string_to_string_matches "{;keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{;keys*}\""
        (of_string_to_string_matches "{;keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?who}\""
        (of_string_to_string_matches "{?who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?half}\""
        (of_string_to_string_matches "{?half}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?x,y}\""
        (of_string_to_string_matches "{?x,y}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?x,y,empty}\""
        (of_string_to_string_matches "{?x,y,empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?x,y,undef}\""
        (of_string_to_string_matches "{?x,y,undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?var:3}\""
        (of_string_to_string_matches "{?var:3}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?list}\""
        (of_string_to_string_matches "{?list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?list*}\""
        (of_string_to_string_matches "{?list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?keys}\""
        (of_string_to_string_matches "{?keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{?keys*}\""
        (of_string_to_string_matches "{?keys*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&who}\""
        (of_string_to_string_matches "{&who}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&half}\""
        (of_string_to_string_matches "{&half}");
      Oth.Assert.true_
        "of_string_to_string_matches \"?fixed=yes{&x}\""
        (of_string_to_string_matches "?fixed=yes{&x}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&x,y,empty}\""
        (of_string_to_string_matches "{&x,y,empty}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&x,y,undef}\""
        (of_string_to_string_matches "{&x,y,undef}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&var:3}\""
        (of_string_to_string_matches "{&var:3}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&list}\""
        (of_string_to_string_matches "{&list}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&list*}\""
        (of_string_to_string_matches "{&list*}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&keys}\""
        (of_string_to_string_matches "{&keys}");
      Oth.Assert.true_
        "of_string_to_string_matches \"{&keys*}\""
        (of_string_to_string_matches "{&keys*}"))

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
  Oth.run ~file:__FILE__ ~setup:(fun () -> Ok ()) ~teardown:(fun _ -> ()) (fun _ -> test)
