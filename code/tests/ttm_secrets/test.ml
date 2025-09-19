module Input_buffer = struct
  type t = {
    buf : Bytes.t;
    mutable pos : int;
  }

  let create buf = { buf; pos = 0 }

  let read t dst pos len =
    let read_len = CCInt.max 0 (CCInt.min len (Bytes.length t.buf - t.pos)) in
    BytesLabels.blit ~src:t.buf ~dst ~src_pos:t.pos ~dst_pos:pos ~len:read_len;
    t.pos <- t.pos + read_len;
    read_len
end

let test_identity =
  Oth.test ~name:"identity" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[]
        ~unmask:[]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this is a test"))

let test_simple_secret =
  Oth.test ~name:"simple secret" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is a" ]
        ~unmask:[]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this *** test"))

let test_simple_unmask =
  Oth.test ~name:"simple unmask" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is a" ]
        ~unmask:[ "is a" ]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this is a test"))

let test_unmask_adjacent_front =
  Oth.test ~name:"unmask adjacent front" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is a" ]
        ~unmask:[ "this " ]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this *** test"))

let test_unmask_adjacent_back =
  Oth.test ~name:"unmask adjacent back" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is a" ]
        ~unmask:[ " test" ]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this *** test"))

let test_unmask_overlap_front =
  Oth.test ~name:"unmask overlap front" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is a" ]
        ~unmask:[ "is is" ]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this is a test"))

let test_unmask_overlap_back =
  Oth.test ~name:"unmask overlap back" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is a" ]
        ~unmask:[ "a te" ]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this is a test"))

let test_unmask_overlap_inside =
  Oth.test ~name:"unmask overlap inside" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is is a" ]
        ~unmask:[ "is" ]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this is a test"))

let test_multiline_secret =
  Oth.test ~name:"multiline secret" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this\nis\na\ntest") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "is\na" ]
        ~unmask:[]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this\n***\ntest"))

let test_multiple_overlapping_secrets =
  Oth.test ~name:"multiple overlapping secrets" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "a"; "is a test"; "is a" ]
        ~unmask:[]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this ***"))

let test_mask_null_byte =
  Oth.test ~name:"mask null byte" (fun _ ->
      let input_buf = Input_buffer.create (Bytes.of_string "this is \u{0000} a test") in
      let output = Buffer.create 10 in
      let fout = Buffer.add_subbytes output in
      Ttm_secrets.Mask.do_mask
        ~secrets:[ "\u{0000}" ]
        ~unmask:[]
        ~mask:(Bytes.of_string "***")
        ~fin:(Input_buffer.read input_buf)
        ~fout
        ();
      assert (Buffer.contents output = "this is *** a test"))

let test =
  Oth.parallel
    [
      test_identity;
      test_simple_secret;
      test_simple_unmask;
      test_unmask_adjacent_front;
      test_unmask_adjacent_back;
      test_unmask_overlap_front;
      test_unmask_overlap_back;
      test_unmask_overlap_inside;
      test_multiline_secret;
      test_multiple_overlapping_secrets;
      test_mask_null_byte;
    ]

let () =
  Random.self_init ();
  Oth.run test
