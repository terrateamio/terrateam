let test_empty_input =
  Oth.test ~desc:"Empty message" ~name:"empty msg" (fun _ ->
      let decoder = Pgsql_codec.Decode.create () in
      let msg1 = Bytes.of_string "" in
      let res = Pgsql_codec.Decode.backend_msg decoder msg1 ~pos:0 ~len:(Bytes.length msg1) in
      assert (res = Ok []))

let test_frontend_encode =
  Oth.test ~desc:"Frontend encode" ~name:"Frontend encode" (fun _ ->
      let frame = Pgsql_codec.Frame.Frontend.Terminate in
      let buf = Buffer.create 1024 in
      Pgsql_codec.Encode.frontend_msg buf frame;
      assert (Buffer.length buf = 5))

let test_partial_msg_decode =
  Oth.test ~desc:"Partial Decode Msg" ~name:"Partial Decode Msg" (fun _ ->
      let decoder = Pgsql_codec.Decode.create () in
      let msg1 = Bytes.of_string "D\000\000\000 \000\002\000\000\000\016Testy McTestface\000\000" in
      let msg2 = Bytes.of_string "\000\00236" in
      let res = Pgsql_codec.Decode.backend_msg decoder msg1 ~pos:0 ~len:(Bytes.length msg1) in
      assert (res = Ok []);
      let res = Pgsql_codec.Decode.backend_msg decoder msg2 ~pos:0 ~len:(Bytes.length msg2) in
      assert (
        res
        = Ok Pgsql_codec.Frame.Backend.[ DataRow { data = [ Some "Testy McTestface"; Some "36" ] } ]
      ))

let test_msg_decode =
  Oth.test ~desc:"MSG" ~name:"MSG" (fun _ ->
      let decoder = Pgsql_codec.Decode.create () in
      let msgs =
        [
          "";
          "R\000\000\000\012\000\000\000\005n\238+y";
          "";
          "R\000\000\000\b\000\000\000\000S\000\000\000\022application_name\000\000S\000\000\000\025client_encoding\000UTF8\000S\000\000\000\023DateStyle\000ISO, \
           MDY\000S\000\000\000\025integer_datetimes\000on\000S\000\000\000\027IntervalStyle\000postgres\000S\000\000\000\021is_superuser\000off\000S\000\000\000\025server_encoding\000UTF8\000S\000\000\000\024server_version\00011.7\000S\000\000\000$session_authorization\000proma_app\000S\000\000\000#standard_conforming_strings\000on\000S\000\000\000\017TimeZone\000UTC\000K\000\000\000\012\000\001Mlj\143\232\160Z\000\000\000\005I";
          "";
          "1\000\000\000\0042\000\000\000\004D\000\000\001\204\000\004\000\000\000\bincanter\000\000\000Cwith-rotation \
           crashes with wrong number of arguments to push-matrix\000\000\001kusing with-rotation \
           from incanter.processing it doesnt work because the required sketch arguments for \
           push-matrix rotate and pop-matrix aren't present in the macro or passed in from without.\n\
           I'm using the latest build (downloaded yesterday) on Solaris 10 java 1.6r17 (ithink)\n\n\
           Sorry for the duplicate but I accidentally closed it and could find the reopen button\n\
           \255\255\255\255D\000\000\006\228\000\004\000\000\000\bincanter\000\000\0003On OSX \
           applet window is missing 22 pixels in height\000\000\006\147The following program \
           (adapted from Shiffman's processing code) doesn't work correctly because the drawable \
           height of the created window is 178 pixels instead of 200 as coded. It does work \
           correctly when the height parameters are changed to 222. It looks suspiciously like the \
           missing 22 pixels are hiding under the window title bar since it is about the same size.\n\n\
           Using the prebuilt zip.\n\n\
           Java version \"1.6.0_20\" on OS X 10.6.3. Running using script/swank and Emacs.\n\n\
           ```\n";
          "";
          "(ns multiprob\n\
           (:use [incanter.core]\n\
          \    [incanter.processing]))\n\
           (let [\n\
          \  p1 (ref 0.05)\n\
          \  p2 (ref (+ @p1 0.8))\n\
          \  r (ref nil)\n\
          \  sktch (sketch\n\
          \         (setup []\n\
          \                (doto this\n\
          \                  (size 200 200)\n\
          \                  smooth\n\
          \                  (framerate 30)\n\
          \                  (background 63 63 63)\n\
          \                  (color-mode RGB 255 255 255)\n\
          \                                        ))\n\
          \         (draw []\n\
          \               (dosync\n\
          \                (ref-set r (rand)))\n\n\
          \               (doto this\n\
          \               (fill 0.0 1.0)\n\
          \               (rect 0 0 (width this) (height this))\n\
          \               (fill (if (< @r @p1)\n\
          \                        255\n\
          \                        (if (< @r @p2)\n\
          \                          150\n\
          \                          0)))\n\n\
          \                 (stroke 200)\n\
          \                 (rect (rem (* 10 (frame-count this)) (width this))\n\
          \                       (rem (* 10 (quot (* 10 (frame-count this)) (width this))) \
           (height this))\n\
          \                       10 10)\n\
          \                 (println (width this) (h";
          "";
          "eight this))\n\
          \                 )))\n\
          \  ]\n\
          \  (view sktch :size [200 200]))\n\
           ```\n\n\
           As a side note, I had an earlier version using the original clj-processing lib working \
           without this problem.\n\
           \255\255\255\255D\000\000\004^\000\004\000\000\000\bincanter\000\000\000\029inconsistent \
           behaviour $join?\000\000\004#Noticed that $joining two datasets returns different \
           columns depending on the order of datasets defined. Let's say I have datasets a and b. \
           First 3 rows of a (take 3 (:rows a))\n\n\
           ```\n\
           {:qual 0.68, :pos \"714038\", :chrom \"1\", :chrom-pos \"1_714038\"}\n\
           {:qual 9.43, :pos \"742584\", :chrom \"1\", :chrom-pos \"1_742584\"}\n\
           {:qual 13.06, :pos \"798494\", :chrom \"1\", :chrom-pos \"1_798494\"}\n\
           ```\n\n\
           First 3 rows of b:\n\n\
           ```\n\
           {:is-present \"yes\", :id-golden \"1_742584\"}\n\
           {:is-present \"yes\", :id-golden \"1_831535\"}\n\
           {:is-present \"yes\", :id-golden \"1_835153\"}\n\
           ```\n\n\
           The chrom-pos column in a matches the id-golden column in b. When I do\n\n\
           ```\n\
           (col-names ($join [:chrom-pos :id-golden] a b))\n\
           ```\n\n\
           I get the following columns: [:id-golden :is-present :qual :pos :chrom]. However, when \
           I turn this around, I miss th";
          "";
          "e is-present column\n\n\
           ```\n\
           (col-names ($join [:id-golden :chrom-pos] b a)) ; => [:chrom-pos :chrom :pos :qual]\n\
           ```\n\n\
           There are records that are in a but not in b, but also the other way around. I suppose \
           that the second version of $join should also include the :found column?\n\n\
           jan.\n\
           \255\255\255\255D\000\000\002\142\000\004\000\000\000\bincanter\000\000\0006Can't load \
           incanter 1.2.3-SNAPSHOT using Clojure 1.1.0\000\000\002:This came up on the IRC channel \
           today:\n\n\
           OSX 10.6.3\n\
           lein 1.2.0-RC1\n\n\
           Steps to repro:\n\
           1. Create a new lien project using http://pastebin.com/QYLnBF50\n\
           2. lein clean && lein deps\n\
           3. lein repl\n\
           4. user=> (use '(incanter core stats))\n\
          \   java.lang.RuntimeException: java.lang.IllegalArgumentException: Don't know how to \
           create ISeq from: clojure.lang.Symbol (core.clj:2)\n\
           5. modify project.clj to use Clojure beta1: http://pastebin.com/BXVeHWWV\n\
           6. lein clean && lein deps && lein repl\n\
           7. user=> (use '(incanter core stats))\n\
           8. it works!\n\n\
           Please contact me if more info is needed.\n\
           \255\255\255\255D\000\000\002\183\000\004\000\000\000\bincanter\000\000\000-Wrong \
           operator precedence with +, -, *, and /\000\000\002lIncanter's inf";
          "";
          "ix feature suggest a surprising ordering of simple arithmetic expressions. Usually, + \
           and - are given an equal precedence value, as well as \\* and / are given an equal one \
           and higher than + and -.\n\n\
           The current setup makes simple expressions result in unexpected values, such as:\n\n\
           ```\n\
           ($= 10 - 1 + 10) ;=> -1, expected 19\n\
           ($= 1 / 2 * 3) ;=> 1/6, expected 3/2\n\
           ```\n\n\
           The fix is to correct lines 2625\226\128\1472628 in \
           `modules/incanter-core/src/incanter/core.clj` to read:\n\n\
           ```\n\
           (defop '- 60 'incanter.core/minus)\n\
           (defop '+ 60 'incanter.core/plus)\n\
           (defop '/ 80 'incanter.core/div)\n\
           (defop '* 80 'incanter.core/mult)\n\
           ```\n\
           \255\255\255\255D\000\000\002\226\000\004\000\000\000\bincanter\000\000\000*jline-0.9.94.jar \
           missing from incanter/lib\000\000\002\154Launching script/repl leads to:\n\
           Exception in thread \"main\" java.lang.NoClassDefFoundError: jline/ConsoleRunner\n\
           Caused by: java.lang.ClassNotFoundException: jline.ConsoleRunner\n\
          \    at java.net.URLClassLoader$1.run(URLClassLoader.java:202)\n\
          \    at java.security.AccessController.doPrivileged(Native Method)\n\
          \    at java.net.URLClassLoader.findClass(";
          "";
          "URLClassLoader.java:190)\n\
          \    at java.lang.ClassLoader.loadClass(ClassLoader.java:307)\n\
          \    at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:301)\n\
          \    at java.lang.ClassLoader.loadClass(ClassLoader.java:248)\n\n\
           Copying jline-0.9.94.jar from lib/dev to lib fixes this issue.\n\
           Is this a problem with the dependencies?\n\
           \255\255\255\255D\000\000\000\246\000\004\000\000\000\bincanter\000\000\000)Typo in \
           incanter.stats/permute docstring.\000\000\000\175Posted on clojuredocs by laughingboy: \
           http://clojuredocs.org/v/3324#comments\n\n\
           http://github.com/liebke/incanter/blob/master/modules/incanter-core/src/incanter/stats.clj#L1875\n\
           \255\255\255\255D\000\000\001>\000\004\000\000\000\bincanter\000\000\000\025API \
           documentation missing\000\000\001\007The documentation at \
           http://liebke.github.com/incanter/ seems to be missing, there are only 6 public methods \
           total, drilling down the documentation seems to be missing completely for most \
           namespaces (example: http://liebke.github.com/incanter/datasets-api.html )\n\
           \255\255\255\255D\000\000\000c\000\004\000\000\000\007riak_kv\000\000\000\022Bz78 http \
           list buckets\000\000\0000See https://issues.basho.com/show_bug.cgi?id=78\n\
           \255\255\255\255D\000\000\0038\000\004\000\000\000\bLinearML\000\000\000\019tree missi";
          "";
          "ng files?\000\000\003\007The files below seem to be missing and give me dependency \
           failures when building... do I need to do something or are source files missing from \
           the tree?\n\n\
           ```\n\
           diff --git a/Makefile b/Makefile\n\
           index 639b5e1..489e089 100644\n\
           --- a/Makefile\n\
           +++ b/Makefile\n\
           @@ -43,7 +43,7 @@ OBJECTS_ML = \\\n\
          \        neast.ml\\\n\
          \        nastExtractFuns.ml\\\n\
          \        nastExpand.ml\\\n\
           -       neastCheck.ml\\\n\
           +       nastCheck.ml\\\n\
          \        tast.ml\\\n\
          \        typing.ml\\\n\
          \        stast.ml\\\n\
           @@ -60,13 +60,9 @@ OBJECTS_ML = \\\n\
          \        estOfIst.ml\\\n\
          \        estOptim.ml\\\n\
          \        estCompile.ml\\\n\
           -       estNormalizePatterns.ml\\\n\
           -       estOptimizePatterns.ml\\\n\
          \        llst.ml\\\n\
           -       llstPp.ml\\\n\
          \        llstOfEst.ml\\\n\
          \        llstFree.ml\\\n\
           -       llstOptim.ml\\\n\
          \        emit2.ml\\\n\
          \        main.ml\n\
          \ #      istAdhoc.ml\n\
           ```\n\
           \255\255\255\255D\000\000\000\161\000\004\000\000\000\bLinearML\000\000\0006better line \
           number tracking and remove hardcoded paths\000\000\000MMakes it easier for me to work \
           on it without conflicts with your local setup\n\
           \255\255\255\255D\000\000\000\238\000\004\000\000\000\bincanter\000\000\000\018Fixed an \
           Excel bug\000\000\000\190Hi,\n\n\
           I posted a bug repor";
          "";
          "t about this problem a while ago on Incanter mailing-list, which still hasn't gone \
           through moderation. But this patch fixes the problem.\n\n\
           Regards,\n\
           V\195\164in\195\182 J\195\164rvel\195\164\n\
           \255\255\255\255D\000\000\001\142\000\004\000\000\000\007riak_kv\000\000\000\023Dont \
           expose testing api\000\000\001ZHello.\n\n\
           If you're including \"eunit/include/eunit.hrl\", then you're defining TEST \
           automatically. This leads to explicit including of test functions into final *.beam \
           files. So I just guarded this include by necessary ifdefs to avoid accidental exposing \
           testing API to the byte-compiler.\n\n\
           This is a minor issue (doesn't really affect the runtime).\n\
           \255\255\255\255D\000\000\000^\000\004\000\000\000\007riak_kv\000\000\000\026bz://863 \
           bitcask keycounts\000\000\000'Please review this commit for bz://863\n\
           \255\255\255\255D\000\000\001\011\000\004\000\000\000\007riak_kv\000\000\000\020Revised \
           pull request\000\000\000\218New version of Friday's pull request which now includes a \
           fixed erlang_js dependency. Tried amending the prior commit but ran into merge issues \
           upstream so I figured it would be cleaner to generate a new pull request.\n\
           \255\255\255\255D\000\000\000|\000\004\000\000\000\007riak_kv\000\000\000\015Fix edoc \
           errors\000\000\000PCorrected a few edoc formatting issues to allow for ";
          "";
          "proper parsing for Erldocs.\n\
           \255\255\255\255D\000\000\001`\000\004\000\000\000\007riak_kv\000\000\000\018Bz882 \
           cluster info\000\000\0011Reviewer: anyone interested\n\n\
           I've rearranged some of the functions in riak_kv_console.erl to do\n\
           double-duty in the name of reusing useful code: spit stuff out \"verbose\"ly\n\
           when riak_kv_console:Foo([]) is called (old-style) and avoid io:format()\n\
           calls when riak_kv_console:Foo(quiet) is called (new-style).\n\
           \255\255\255\255D\000\000\000\189\000\004\000\000\000\007riak_kv\000\000\000\019Dss \
           status refactor\000\000\000\141Please review and test these changes to the \
           console/cluster_info code. Without this change, we are unable to run basho_expect to \
           completion.\n\
           \255\255\255\255D\000\000\001~\000\004\000\000\000\007riak_kv\000\000\000\025Bz932 no \
           transfers active\000\000\001HReviewer: Dizzy ('cept that he's really busy this week) or \
           anyone else (preferably).\n\n\
           I added the missing message as well as changed the return value so that\n\
           the exit status of \"riak-admin transfers\" will be non-zero when the # of pending\n\
           transfers is non-zero.\n\n\
           NOTE: this needs to go to both riak_kv-0.14 and master branches.\n\
           \255\255\255\255D\000\000\000\210\000\004\000\000\000\007riak_kv\000\000\000\017Bz937 \
           filter keys\000\000\000\164Just needed an extra fu";
          "";
          "nction clause to match the format of the key filter produced by riak_client:filter_keys.\n\n\
           Fixes https://issues.basho.com/show_bug.cgi?id=937\n\
           \255\255\255\255D\000\000\001C\000\004\000\000\000\007riak_kv\000\000\0003Fix for Issue \
           937 regarding riak_client:filter_keys\000\000\000\243riak_client:filter_keys produces a \
           different \"filter\" format than other functions.  This patch fixes the issue in the \
           same manner that bucket-listing was fixed: by adding a function clause to the filter \
           builder to handle the alternate format.\n\
           \255\255\255\255D\000\000\000\171\000\004\000\000\000\007riak_kv\000\000\000/Proposed \
           fix for spurious JS timeouts (bz #938)\000\000\000_This patch addresses spurious \
           timeouts generating during periods of heavy Javascript VM usage.\n\
           \255\255\255\255D\000\000\001~\000\004\000\000\000\007riak_kv\000\000\000\021Bz933 \
           missing key map\000\000\001LThese patches prevent map/reduce jobs from failing (with \
           'exhausted_preflist' errors) when non-existent bucket/keys are sent to map phases.  \
           They restore the 0.13.0 behavior of evaluating Erlang map functions with the {error, \
           notfound} tuple, and of substituting a \"not_found\" result in lieu of evaluating \
           Javascript map functions.\n\
           \255\255\255\255";
          "";
          "D\000\000\001;\000\004\000\000\000\007riak_kv\000\000\000\026Bz927 cluster info \
           console\000\000\001\004Reviewer: any, it's small\n\n\
           If this pull is reviewed & approved before the Dakota release, I'll also merge it (and \
           riak-admin) changes into the Dakota release branch.  If not approved, then it can wait \
           here in the pull queue until after Dakota is out the door.\n\
           \255\255\255\255D\000\000\001\031\000\004\000\000\000\007riak_kv\000\000\000\"Bz210 \
           bitcask multi backend compat\000\000\000\224Enables riak_kv_bitcask_backend to receive \
           per-instance configuration, thus making it compatible with riak_kv_multi_backend. Still \
           falls back on application config when not specified.\n\n\
           Not critical to pull before/into 0.14.\n\
           \255\255\255\255D\000\000\001\031\000\004\000\000\000\007riak_kv\000\000\000\"Bz210 \
           bitcask multi backend compat\000\000\000\224Enables riak_kv_bitcask_backend to receive \
           per-instance configuration, thus making it compatible with riak_kv_multi_backend. Still \
           falls back on application config when not specified.\n\n\
           Not critical to pull before/into 0.14.\n\
           \255\255\255\255D\000\000\000\189\000\004\000\000\000\007riak_kv\000\000\000JBug 964 - \
           riak_kv_mapred_term doesn't understand key-filters (Protobuffs) \000\000\000VFixes bug \
           where JSON format unde";
          "";
          "rstands key filters but Erlang-terms format does not.\n\
           \255\255\255\255D\000\000\002\252\000\004\000\000\000\007riak_kv\000\000\000\018Patch A \
           for BZ 969\000\000\002\205This patch solves the cache limit overrun bug described in \
           https://issues.basho.com/show_bug.cgi?id=969.\n\n\
           The method for solving the bug that this patch uses is to convert riak_kv_lru into a \
           gen_server.  This serializes all modifications to the cache.  Unfortunately, it also \
           serializes all cache lookups, but that could probably be changed in a second commit (by \
           using protected tables, and exposing their names).\n\n\
           Another option was to serialize all modifications through riak_kv_mapred_cache.  This \
           patch adds the riak_kv_lru gen_server instead, in order to limit the changes to one \
           file.  Serializing through riak_kv_mapred_cache would have required editing \
           riak_kv_mapred_cache, riak_kv_mapper, and riak_kv_lru.\n\
           \255\255\255\255D\000\000\001 \000\004\000\000\000\bincanter\000\000\000\027$where for \
           non numeric data\000\000\000\231$where only worked on numeric data since query-to-pred \
           used the >, <, >=, <= functions.\n\n\
           I changed it to use the compare function. It will now work";
          "";
          " with numeric data using the clojure number tree _and_ anything that is Comparable.\n\
           \255\255\255\255D\000\000\001\159\000\004\000\000\000\bincanter\000\000\000!factorial \
           broken on (factorial 0)\000\000\001`According to Wikipedia, factorial(0) is \
           special-cased to be 0. incanter.core/factorial has an incorrect pre-condition, it \
           checks for (pos? k) rather than (not (neg? k)), throwing an exception on (factorial 0). \n\n\
           I've tested that (cern.jet.math.tdouble.DoubleArithmetic/factorial 0) handles it \
           correctly, so only the precondition needs to be modified. \n\
           \255\255\255\255D\000\000\002\138\000\004\000\000\000\007riak_kv\000\000\000\025Key \
           count reduce function\000\000\002TThe intention of this patch is to provide a suitable \
           function for\n\
           counting the keys in a bucket via keylist+map/reduce.  Using this\n\
           function saves bandwidth over counting on the client side (with\n\
           ?keys=stream, for example) because keys are never sent to the client.\n\
           Using this function saves I/O over a query including a map phase because\n\
           the values stored under the keys are never read from disk.\n\n\
           It still uses the regular list-keys process under the hood, but it at ";
          "";
          "least abstracts the framework necessary for handling the streamed keylists.\n\n\
           See the commit message or edoc for example usage.\n\
           \255\255\255\255D\000\000\000+\000\004\000\000\000\bincanter\000\000\000\rsimple \
           f-test\000\000\000\000\255\255\255\255C\000\000\000\014SELECT 32\000Z\000\000\000\005I";
          "";
        ]
      in
      List.iter
        (fun s ->
          let s = Bytes.of_string s in
          match Pgsql_codec.Decode.backend_msg decoder s ~pos:0 ~len:(Bytes.length s) with
            | Ok _    -> ()
            | Error _ -> assert false)
        msgs)

let test =
  Oth.parallel [ test_empty_input; test_frontend_encode; test_partial_msg_decode; test_msg_decode ]

let () = Oth.run test
