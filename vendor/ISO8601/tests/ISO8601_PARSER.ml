let test p fn input expected =
  let result = fn input in
  let assert_equal = OUnit.assert_equal
                       ~cmp:(OUnit.cmp_float ~epsilon:Pervasives.epsilon_float)
                       ~printer:p in
  OUnit.(>::) input (fun _ -> assert_equal expected result)

let date = test ISO8601.Permissive.string_of_date ISO8601.Permissive.date

let time = test ISO8601.Permissive.string_of_time ISO8601.Permissive.time

let datetime = test ISO8601.Permissive.string_of_datetime ISO8601.Permissive.datetime

(* Parser tests *)
let suite =
  let mkdatetime = Utils.mkdatetime in
  let mkdate = Utils.mkdate in
  let mktime = Utils.mktime in
  OUnit.(>:::) "[PARSER]" [
    OUnit.(>:::) "[DATE]"
          [
            date "1970-01-01" 0. ;
            date "19700101" 0. ;
            date "1970-01" 0. ;
            date "197001" 0. ;
            date "1970" 0. ;
            date "2009" (mkdate 2009 1 1) ;
            date "2009-05-19" (mkdate 2009 5 19) ;
            date "20090519" (mkdate 2009 5 19) ;
            date "2009-05" (mkdate 2009 5 1) ;
            date "2009-001" (mkdate 2009 1 1);
            date "2009-123" (mkdate 2009 5 3);
            date "2009-222" (mkdate 2009 8 10);
            date "2009-139" (mkdate 2009 5 19);
            date "2012-060" (mkdate 2012 2 29); (* leap year *)
          ] ;
    OUnit.(>:::) "[TIME WITHOUT TIMEZONE]"
          [
            time "12:34" (mktime 12. 34. 0.) ;
            time "00:00" (mktime 0. 0. 0.) ;
            time "14" (mktime 14. 0. 0.) ;
            time "14:31" (mktime 14. 31. 0.) ;
            time "14:39:22" (mktime 14. 39. 22.) ;
            time "24:00" (mktime 24. 0. 0.) ;
            time "16:23:48.5" (mktime 16. 23. 48.5) ;
            time "16:23:48,444" (mktime 16. 23. 48.444) ;
            time "16:23.4" (mktime 16. 23.4 0.) ;
            time "16:23,25" (mktime 16. 23.25 0.);
            time "16.23334444" (mktime 16.23334444 0. 0.);
            time "16,2283" (mktime 16.2283 0. 0.);
          ] ;
    OUnit.(>:::) "[TIME WITH TIMEZONE]"
          [
            time "14:39:22-06:00" (mktime 20. 39. 22.) ;
            time "14:39:22+0600" (mktime 8. 39. 22.);
            time "14:39:22-01" (mktime 15. 39. 22.);
            time "0545Z" (mktime 5. 45. 0.);
            time "16:23:48,3-06:00" (mktime 22. 23. 48.3) ;
            time "16:23.33+0600" (mktime 10. 23.33 0.) ;
          ] ;
    OUnit.(>:::) "[DATETIME WITHOUT TIMEZONE]"
          [
            datetime "2015-02-15T11:55" (mkdatetime 2015 02 15 11 55 0) ;
          ] ;
  ]
