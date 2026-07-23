let test (fn : float -> string) (input : float) (expected : string)  =
  let result = fn input in
  let assert_equal = OUnit.assert_equal ~printer:(fun x -> x) in
  OUnit.(>::) (string_of_float input)
        (fun _ -> assert_equal expected result)

let date = test ISO8601.Permissive.string_of_date

let time = test ISO8601.Permissive.string_of_time

let datetime = test ISO8601.Permissive.string_of_datetime

let datetimezone input expected =
  let assert_equal = OUnit.assert_equal ~printer:(fun x -> x) in
  OUnit.(>::) (string_of_float (fst input))
       (fun _ -> assert_equal
                   expected
                   (ISO8601.Permissive.string_of_datetimezone input))

let suite =
  let mkdate = Utils.mkdate in
  OUnit.(>:::) "[PRINTER]" [
    OUnit.(>:::) "[PRINTER DATE]"
          [
            date 0. "1970-01-01" ;
            date (24. *. 3600.) "1970-01-02" ;
            date (31. *. 24. *. 3600.) "1970-02-01" ;
            date (365. *. 24. *. 3600.) "1971-01-01" ;
            date (mkdate 2009 1 1) "2009-01-01" ;
            date (mkdate 2009 5 19) "2009-05-19" ;
            date 583804800. "1988-07-02" ;
            date (mkdate 1988 7 2) "1988-07-02" ;
          ];
    OUnit.(>:::) "[PRINTER TIME]"
          [
            time 0. "00:00:00" ;
            time 1. "00:00:01" ;
            time 60. "00:01:00" ;
            time 3600. "01:00:00" ;
          ] ;
    OUnit.(>:::) "[PRINTER DATETIMEZONE]"
          [
            datetimezone (0., 0.) "1970-01-01T00:00:00+00:00" ;
            datetimezone (296638320., 0.) "1979-05-27T07:32:00+00:00"
          ] ;
  ]
